# Input Instruction
# Output bin data

# Format: [opcode - 5][arg1 - 9][arg2 - 9][arg3 - 9]
# Instruction format:
# [OPCODE][ARG1][ARG2]

from enum import IntEnum
from typing import Literal
import re

class Opcode(IntEnum):
    NOP    = 0
    ADD    = 1
    SUB    = 2
    MUL    = 3
    DIV    = 4
    ADDI   = 5
    SUBI   = 6
    MOV    = 7
    LOAD   = 8
    LOADI  = 9       # Save to register with an immediate number, e.g. LOADI R0 2
    LOADR  = 10
    STORE  = 11       # Save to RAM
    STORER = 12
    JMP    = 13
    JNZ    = 14      # Jump if the register is zero, e.g. JZ R3 ADD_SECTION
    JAL	   = 15
    JMPR   = 16
    BEQ    = 17
    BNE    = 18
    BLT    = 19
    BGE    = 20
    HALT   = 21
    
class Register(IntEnum):
    R0 = 0
    R1 = 1
    R2 = 2
    R3 = 3
    R4 = 4
    R5 = 5
    R6 = 6
    R7 = 7

type DataType = Literal["RD", "RS1", "RS2", "IMM", "BRAM", "LABEL"]

INSTRUCTION_FORMATS: dict[str, list[tuple[DataType, int]]] = {
    "NOP":      [],                                         # 0 args
    "ADD":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [3 bit reg, 3 bit reg, 3 bit reg]
    "SUB":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [3 bit reg, 3 bit reg, 3 bit reg]
    "MUL":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [3 bit reg, 3 bit reg, 3 bit reg]
    "DIV":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [3 bit reg, 3 bit reg, 3 bit reg]
    "ADDI":     [("RD", 3), ("RS1", 3), ("IMM", 16)],       # [3 bit reg, 3 bit reg, 16 bit literal]
    "SUBI":     [("RD", 3), ("RS1", 3), ("IMM", 16)],       # [3 bit reg, 3 bit reg, 16 bit literal]
    "MOV":      [("RD", 3), ("RS1", 3)],                    # [3 bit reg, 3 bit reg]
    "LOAD":     [("RD", 3), ("BRAM", 16)],                  # [3 bit reg, 16 bit BRAM]
    "LOADI":    [("RD", 3), ("IMM", 16)],                   # [3 bit reg, 16 bit literal]
    "LOADR":    [("RD", 3), ("RS1", 3)],                    # [3 bit reg, 3 bit reg]
    "STORE":    [("RS1", 3), ("BRAM", 16)],                 # [3 bit reg, 16 bit BRAM]
    "STORER":   [("RS1", 3), ("RS2", 3)],                   # [3 bit reg, 3 bit reg]
    "JMP":      [("LABEL", 16)],                            #[16 bit label]
    "JNZ":      [("RS1", 3), ("LABEL", 16)],                # [3 bit reg, 16 bit label]
    "JAL":      [("RD", 3), ("LABEL", 16)],                 # [3 bit reg, 16 bit literal]
    "JMPR":     [("RS1", 3)],                               # [3 bit reg]
    "BEQ":      [("RS1", 3), ("RS2", 3), ("LABEL", 16)],    # [3 bit reg, 3 bit reg, 16 bit label]
    "BNE":      [("RS1", 3), ("RS2", 3), ("LABEL", 16)],    # [3 bit reg, 3 bit reg, 16 bit label]
    "BLT":      [("RS1", 3), ("RS2", 3), ("LABEL", 16)],    # [3 bit reg, 3 bit reg, 16 bit label]
    "BGE":      [("RS1", 3), ("RS2", 3), ("LABEL", 16)],    # [3 bit reg, 3 bit reg, 16 bit label]
    "HALT":     [],                                         # 0 args
}

SLOT_OFFSET: dict[DataType, int] = {
    "RD": 24,
    "RS1": 21,
    "RS2": 18,
    "IMM": 2,
    "LABEL": 2,
    "BRAM": 2
}

compiled_instruction: list[str] = []

def encode(code: str, arg1: int | str | None = None, arg2: int | str | None = None, arg3: int | str | None = None) -> None:
    print(code, arg1, arg2, arg3)
    instruction_val = Opcode[code] << 27

    formats = INSTRUCTION_FORMATS[code]
    args: list[int | str] = []
    for a in (arg1, arg2, arg3):
        if a is not None:
            args.append(a)

    
    for arg_val, format_spec in zip(args, formats):
        field_type = format_spec[0]
        parsed_val = parse_operand(arg_val, format_spec)
        
        offset = SLOT_OFFSET[field_type]
        instruction_val |= (parsed_val << offset)

    bit_stream = f"{instruction_val:032b}"
    compiled_instruction.append(bit_stream)

def parse_operand(arg: int | str, data: tuple[DataType, int]) -> int:
    """"Turn string code into binary in string form | e.g. ADD = 1 = 00001"""
    field_type = data[0]
    width = data[1]

    if field_type in ("RD", "RS1", "RS2"):
        if isinstance(arg, str) and arg in Register.__members__:
            num = Register[arg].value
        else:
            raise ValueError(f"Expected a Register (e.g., R0), got {arg}")

    else:
        if isinstance(arg, str) and arg in Register.__members__:
            raise ValueError(f"Expected a number, got Register {arg}")
        try:
            num = int(arg)
        except ValueError as e:
            raise ValueError(f"Invalid immediate value '{arg}'") from e


    if not (0 <= num <= (1 << width) - 1): # (2 ** width) - 1 
        raise ValueError(f"Immediate value {num} out of range.")
    return num

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
            raise IndexError(f"Argument provided does not match. Needed {len(INSTRUCTION_FORMATS[opcode])}, got {len(temp_instruction) - 1} instead. Instruction: {temp_instruction}")

        if opcode in ('HALT', 'NOP'):
            pass
        elif opcode == 'JMP':
            # expect label in arg1
            arg1 = label_name.get(temp_instruction[1], None)
            if arg1 == None:
                raise ValueError(f"Label {temp_instruction[1]} not found.")
        elif opcode in ('JNZ', 'JAL'):
            # expect label in arg2
            arg1 = temp_instruction[1] # reg addr - 3 bit
            arg2 = label_name.get(temp_instruction[2], None) # label - 16 bit
            if arg2 == None:
                raise ValueError(f"Label {temp_instruction[2]} not found.")
        elif opcode in ('BEQ', 'BNE', 'BLT', 'BGE'):
            arg1 = temp_instruction[1]
            arg2 = temp_instruction[2]
            arg3 = label_name.get(temp_instruction[3], None) # label
            if arg3 == None:
                raise ValueError(f"Label {temp_instruction[3]} not found.")
        elif opcode in ('ADD', 'SUB', 'MUL', 'DIV', 'ADDI', 'SUBI'): # ALU / Branch, 3 args
            arg1 = temp_instruction[1]
            arg2 = temp_instruction[2]
            arg3 = temp_instruction[3]
        elif opcode in ('LOADI', 'LOAD', 'STORE', 'MOV', 'LOADR', 'STORER'): # 2 args
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