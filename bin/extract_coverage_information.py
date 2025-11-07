#!/usr/bin/env python3

import argparse
import platform


def dump_versions(process_name):
    """
    Dump the current Python version into a 'versions.yml' file.

    This function writes the process name and the current Python version into a YAML file named 'versions.yml'.

    Parameters:
    - process_name(str): A string representing the name of the process to be included in the file.
    """
    with open("versions.yml", "w", encoding="UTF-8") as out_f:
        out_f.write(process_name + ":\n")
        out_f.write("    python: " + platform.python_version() + "\n")


def read_specific_line(file_path, line_number):
    """
    Read specific line (set to 5 (line 6 due to 0 index)) from the input file.
    :param file_path:   Path to text file to read.
    :param line_number: Line number to read.
    :return:            A string on the line read, or statement line number beyond end of text file.
    """
    with open(file_path, 'r') as file:
        for current_line_number, line in enumerate(file):
            if current_line_number == line_number:
                return line.strip()
    return "Line number out of range"


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--process_name", default="!{process_name}")
    parser.add_argument("--input", default="!{input}")
    parser.add_argument("--output", default="!{output}")
    args = parser.parse_args()

input_file = args.input

coverage_line_number = 5

coverage_line = read_specific_line(input_file, coverage_line_number)

coverage_value = coverage_line[80:len(coverage_line)]

with open(args.output, "w") as text_file:
    print(coverage_value, file=text_file)
