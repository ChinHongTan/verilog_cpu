# Input Instruction
# Output bin data

# Format: [opcode - 5][arg1 - 9][arg2 - 9][arg3 - 9]
# Instruction format:
# [OPCODE][ARG1][ARG2]

from enum import IntEnum
from typing import Literal
import re

class Opcode(IntEnum):
    ADD   = 1
    SUB   = 2
    MUL   = 3
    DIV   = 4
    MOV   = 5
    LOAD  = 6
    LOADI = 7       # Save to register with an immediate number, e.g. LOADI R0 2
    LOADR = 8
    STORE = 9       # Save to RAM
    JMP   = 10
    JNZ   = 11      # Jump if the register is zero, e.g. JZ R3 ADD_SECTION
    JAL	  = 12
    JMPR  = 13
    BEQ   = 14
    BNE   = 15
    BLT   = 16
    BGE   = 17
    HALT  = 18
    
class Register(IntEnum):
    R0 = 0
    R1 = 1
    R2 = 2
    R3 = 3
    R4 = 4
    R5 = 5
    R6 = 6
    R7 = 7

type DataType = Literal["REG", "IMM", "BRAM", "LABEL"]

INSTRUCTION_FORMATS: dict[str, list[tuple[DataType, int]]] = {
    "ADD":      [("REG", 3), ("REG", 3), ("REG", 3)],       # [3 bit reg, 3 bit reg, 3 bit reg]
    "SUB":      [("REG", 3), ("REG", 3), ("REG", 3)],       # [3 bit reg, 3 bit reg, 3 bit reg]
    "MUL":      [("REG", 3), ("REG", 3), ("REG", 3)],       # [3 bit reg, 3 bit reg, 3 bit reg]
    "DIV":      [("REG", 3), ("REG", 3), ("REG", 3)],       # [3 bit reg, 3 bit reg, 3 bit reg]
    "MOV":      [("REG", 3), ("REG", 3)],                   # [3 bit reg, 3 bit reg]
    "LOAD":     [("REG", 3), ("BRAM", 16)],                 # [3 bit reg, 16 bit BRAM]
    "LOADI":    [("REG", 3), ("IMM", 16)],                  # [3 bit reg, 16 bit literal]
    "LOADR":    [("REG", 3), ("REG", 3)],                   # [3 bit reg, 3 bit reg]
    "STORE":    [("REG", 3), ("BRAM", 16)],                 # [3 bit reg, 16 bit BRAM]
    "JMP":      [("REG", 3), ("LABEL", 16)],                # [3 bit padding, 16 bit label]
    "JNZ":      [("REG", 3), ("LABEL", 16)],                # [3 bit reg, 16 bit label]
    "JAL":      [("REG", 3), ("IMM", 16)],                  # [3 bit reg, 16 bit literal]
    "JMPR":     [("REG", 3)],                               # [3 bit reg]
    "BEQ":      [("REG", 3), ("REG", 3), ("LABEL", 16)],    # [3 bit reg, 3 bit reg, 16 bit label]
    "BNE":      [("REG", 3), ("REG", 3), ("LABEL", 16)],    # [3 bit reg, 3 bit reg, 16 bit label]
    "BLT":      [("REG", 3), ("REG", 3), ("LABEL", 16)],    # [3 bit reg, 3 bit reg, 16 bit label]
    "BGE":      [("REG", 3), ("REG", 3), ("LABEL", 16)],    # [3 bit reg, 3 bit reg, 16 bit label]
    "HALT":     [],                                         # 0 args
}

compiled_instruction: list[str] = []

def encode(code: str, arg1: int | str | None = None, arg2: int | str | None = None, arg3: int | str | None = None) -> None:
    print(code, arg1, arg2, arg3)
    bit_stream = ""
    opcode_bin = f"{Opcode[code]:05b}" # 5 bit
    bit_stream += opcode_bin

    widths = INSTRUCTION_FORMATS[code]
    args: list[int | str] = []
    for a in (arg1, arg2, arg3):
        if a is not None:
            args.append(a)

    for i in range(len(args)):
        val = args[i]  # ADD R0 R1 R2 | LOADI R0 1000 | STORE R0 12
        width = widths[i]

        bit_stream += parse_operand(val, width) #TODO

    bit_stream = bit_stream.ljust(32, "0") # fill 0 in the end
    compiled_instruction.append(bit_stream)

def parse_operand(arg: int | str, data: tuple[DataType, int]) -> str:
    """"Turn string code into binary in string form | e.g. ADD = 1 = 00001"""
    field_type = data[0]
    width = data[1]

    if field_type == "REG":
        if isinstance(arg, str) and arg in Register.__members__:
            num = Register[arg].value
        else:
            raise ValueError(f"Expected a Register (e.g., R0), got {arg}")

    elif field_type == "IMM" or "BRAM" or "LABEL":
        if isinstance(arg, str) and arg in Register.__members__:
            raise ValueError(f"Expected a number, got Register {arg}")
        try:
            num = int(arg)
        except ValueError as e:
            raise ValueError(f"Invalid immediate value '{arg}'") from e


    if not (0 <= num <= (2**width) - 1): # (1 << width) - 1 
        raise ValueError(f"Immediate value {num} out of range.")
    return f"{num:0{width}b}"

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
        arg1 = None
        arg2 = None
        arg3 = None

        if len(temp_instruction) - 1 != len(INSTRUCTION_FORMATS[opcode]):
            raise IndexError(f"Argument provided does not match. Needed {len(INSTRUCTION_FORMATS[opcode])}, got {len(temp_instruction) - 1} instead.")

        if opcode == 'HALT':
            pass
        elif opcode == 'JMP':
            # expect label in arg1
            arg1 = "R0" # 3 bit padding for verilog
            arg2 = label_name.get(temp_instruction[1], None)
            if arg2 == None:
                raise ValueError(f"Label {temp_instruction[1]} not found.")
        elif opcode == 'JNZ':
            # expect label in arg2
            arg1 = temp_instruction[1] # reg addr - 3 bit
            arg2 = label_name.get(temp_instruction[2], None) # label - 16 bit
            if arg2 == None:
                raise ValueError(f"Label {temp_instruction[2]} not found.")
        elif opcode in ('ADD', 'SUB', 'MUL', 'DIV', 'BEQ', 'BNE', 'BLT', 'BGE'): # ALU / Branch, 3 args
            arg1 = temp_instruction[1]
            arg2 = temp_instruction[2]
            arg3 = temp_instruction[3]
        elif opcode in ('LOADI', 'LOAD', 'STORE', 'MOV', 'JAL', 'LOADR'): # 2 args
            arg1 = temp_instruction[1]
            arg2 = temp_instruction[2]
        elif opcode == 'JMPR':
            arg1 = temp_instruction[1]
        else:
            raise SyntaxError(f"Unknown opcode: {opcode}")

        encode(opcode, arg1, arg2, arg3)

print(compiled_instruction)

with open("ex1.mem", "w", encoding="utf-8") as f:
    for i in compiled_instruction:
        f.write(i + "\n")

    print("Write complete.")