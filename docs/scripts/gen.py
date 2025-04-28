import os
import re
import sys

def write_class(file_path, class_name):
    with open(file_path, 'a') as f:
        f.write(f".. title:: {class_name}\n")
        f.write(f".. lua:autoobject:: {class_name}\n")
        f.write("   :members:\n")
        f.write("   :special-members: __new\n")
        f.write("   :undoc-members:\n")
        f.write("   :inherited-members: __new\n\n")

def process_files(input_dir, output_dir):
    """
    Recursively iterate over a directory, search for the first instance of "@class" in each file,
    and rewrite the file in the RST format, replacing "Actor" with the class name found after "@class".

    :param input_dir: Path to the input directory containing files to process.
    :param output_dir: Path to the output directory where modified files will be saved.
    """
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for root, _, files in os.walk(input_dir):
        for file in files:
            input_file_path = os.path.join(root, file)
            output_file_path = os.path.join(output_dir, os.path.relpath(input_file_path, input_dir))
            output_file_path = os.path.splitext(output_file_path)[0] + ".rst"

            # Ensure the output directory structure exists
            os.makedirs(os.path.dirname(output_file_path), exist_ok=True)

            with open(input_file_path, 'r') as f:
                content = f.readlines()

            class_name = None
            for line in content:
                match = re.search(r'@class\s+(\w+)', line)
                if match:
                    class_name = match.group(1)
                    write_class(output_file_path, class_name)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 gen.py <input_directory> <output_directory>")
        sys.exit(1)

    input_directory = sys.argv[1]
    output_directory = sys.argv[2]
    process_files(input_directory, output_directory)

