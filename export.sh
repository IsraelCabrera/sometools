#!/bin/bash

set -e

# Function to select a .kicad_pcb file
select_kicad_pcb_file() {
    local files=()
    local count=0
    
    # Find all .kicad_pcb files in current directory, ignoring autosave files
    while IFS= read -r -d $'\0' file; do
        filename=$(basename "$file")
        # Skip files starting with _autosave
        if [[ "$filename" != _autosave* ]]; then
            files+=("$file")
            ((count++))
        fi
    done < <(find . -maxdepth 1 -name "*.kicad_pcb" -type f -print0)
    
    if [ $count -eq 0 ]; then
        echo "Error: No .kicad_pcb files found in current directory." >&2
        echo "       (Ignoring files starting with '_autosave')" >&2
        exit 1
    elif [ $count -eq 1 ]; then
        # Return the single file found
        echo "${files[0]}"
        return 0
    else
        # Multiple files found, prompt user to select one
        echo "Multiple .kicad_pcb files found. Please select one:" >&2
        echo "" >&2
        
        for i in "${!files[@]}"; do
            echo "$((i+1)). ${files[$i]#./}" >&2
        done
        
        echo "" >&2
        
        while true; do
            read -p "Enter number (1-$count): " selection >&2
            
            # Check if input is a valid number
            if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "$count" ]; then
                echo "${files[$((selection-1))]}"
                return 0
            else
                echo "Invalid selection. Please enter a number between 1 and $count." >&2
            fi
        done
    fi
}

# Main script logic
if [ $# -eq 0 ]; then
    # No argument provided, find .kicad_pcb file in current directory
    echo "No file specified. Looking for .kicad_pcb files in current directory..."
    input_file=$(select_kicad_pcb_file)
    echo "Selected file: $input_file"
else
    # Use the provided argument
    input_file="$1"
fi

# Verify the file exists
if [ ! -f "$input_file" ]; then
    echo "Error: File '$input_file' does not exist."
    exit 1
fi

# Extract filename without extension
filename=$(basename -- "$input_file")
filename="${filename%.*}"

echo "Processing: $input_file"

# Create output directory
mkdir -p output

# Export gerbers and drill files
kicad-cli pcb export gerbers -o output -l B.Cu,Edge.Cuts "$input_file"
kicad-cli pcb export drill -o output "$input_file"

# Create gcode directory
mkdir -p gcode

# Run pcb2gcode via Docker
docker run --rm -i -t \
    -v ".:/data" \
    -v "/projects/tools/pcb2gcode/millproject:/config/millproject:ro" \
    ptodorov/pcb2gcode \
    --config /config/millproject \
    --back="output/$filename-B_Cu.gbl" \
    --drill="output/$filename.drl" \
    --outline="output/$filename-Edge_Cuts.gm1"

# Fix permissions
sudo chown -R $USER:$USER gcode

echo "Done! GCode files are in the 'gcode' directory."