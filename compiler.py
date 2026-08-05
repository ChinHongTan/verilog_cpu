# Input Instruction
# Output bin data

# Format: [empty - 4 bit][opcode - 4 bit][regAddr1 - 4 bit][regAddr2 - 4 bit]
# Instruction format:
# [OPCODE][ARG1][ARG2]

from enum import IntEnum
import re

class Opcode(IntEnum):
    ADD = 1
    SUB = 2
    MUL = 3
    DIV = 4
    JMP = 5
    JNZ = 6         # Jump if the register is zero, e.g. JZ R3 ADD_SECTION
    HALT = 7
    STORE = 8       # Save to RAM
    LOAD = 9
    LOADI = 10      # Save to register with an immediate number, e.g. LOADI R0 2

class Register(IntEnum):
    R0 = 0
    R1 = 1
    R2 = 2
    R3 = 3
    R4 = 4
    R5 = 5
    R6 = 6
    R7 = 7

compiled_instruction: list[str] = []

def encode(code: str, arg1: int | str, arg2: int | str) -> None:
    print(code, arg1, arg2)
    empty_bin = f"{0:04b}" # 4 empty bit
    opcode_bin = f"{Opcode[code]:04b}" # 4 bit

    reg_bin_1 = parse_operand(arg1) # 3 bit
    reg_bin_2 = parse_operand(arg2) # 3 bit

    compiled_instruction.append(f"{empty_bin}{opcode_bin}{reg_bin_1}{reg_bin_2}")

def parse_operand(arg: int | str) -> str:
    # Try as Register
    if isinstance(arg, str) and arg in Register.__members__:
        reg_val = Register[arg].value
        return f"1{reg_val:03b}"

    try:
        num = int(arg)
    except ValueError as e:
        raise ValueError(f"Invalid operand {arg}: must be a valid Register or number.") from e

    if not (0 <= num <= 7):
        raise ValueError(f"Immediate value {num} out of range.")
    return f"0{num:03b}"

with open("program.txt", "r", encoding="utf-8") as f:
    label_name: dict[str, int] = {}
    line_num = 0
    temp_instructions: list[list[str]] = []
    for lines in f:
        clean_line = lines.strip().split(";", 1)[0] # Remove comments
        clean_line = clean_line.strip() # strip again to remove white spaces between comment and code

        if not clean_line: # empty line
            continue

        if clean_line.endswith(":"):
            label_name[clean_line[:-1]] = line_num
            continue

        parts = re.split(r"[\s,]+", clean_line.strip()) # Accept both ADD R0 R1 and ADD R0, R1
        temp_instructions.append(parts)
        line_num += 1

    print("Total instuctions: ", len(temp_instructions))
    print(temp_instructions)

    for temp_instruction in temp_instructions:

        opcode = temp_instruction[0]
        arg1 = 0
        arg2 = 0

        if opcode == 'HALT':
            pass
        elif opcode == 'JMP':
            # expect label in arg1
            arg1 = label_name.get(temp_instruction[1], None)
            if arg1 == None:
                raise ValueError(f"Label {temp_instruction[1]} not found.")
        elif opcode == 'JNZ':
            # expect label in arg2
            arg1 = temp_instruction[1]
            arg2 = label_name.get(temp_instruction[2], None)
            if arg2 == None:
                raise ValueError(f"Label {temp_instruction[2]} not found.")
        elif opcode in ('ADD', 'SUB', 'MUL', 'DIV', 'LOADI', 'LOAD', 'STORE'):
            arg1 = temp_instruction[1]
            arg2 = temp_instruction[2]
        else:
            raise SyntaxError(f"Unknown opcode: {opcode}")

        encode(opcode, arg1, arg2)

print(compiled_instruction)

with open("ex1.mem", "w", encoding="utf-8") as f:
    for i in compiled_instruction:
        f.write(i + "\n")

    print("Write complete.")