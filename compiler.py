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
    "ADD":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [ADD rd rs1 rs2]
    "SUB":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [SUB rd rs1 rs2]
    "MUL":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [MUL rd rs1 rs2]
    "DIV":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [DIV rd rs1 rs2]
    "ADDI":     [("RD", 3), ("RS1", 3), ("IMM", 16)],       # [ADDI rd rs1 imm]
    "SUBI":     [("RD", 3), ("RS1", 3), ("IMM", 16)],       # [SUBI rd rs1 imm]
    "MOV":      [("RD", 3), ("RS1", 3)],                    # [MOV rd rs1]
    "LOAD":     [("RD", 3), ("BRAM", 16)],                  # [LOAD rd bram]
    "LOADI":    [("RD", 3), ("IMM", 16)],                   # [LOADI rd imm]
    "LOADR":    [("RD", 3), ("RS1", 3)],                    # [LOADR rd rs1]
    "STORE":    [("RS1", 3), ("BRAM", 16)],                 # [STORE rs1 bram]
    "STORER":   [("RS1", 3), ("RS2", 3)],                   # [STORER rs1 rs2]
    "JMP":      [("LABEL", 16)],                            # [JMP label]
    "JNZ":      [("RS1", 3), ("LABEL", 16)],                # [JNZ rs1 label]
    "JAL":      [("RD", 3), ("LABEL", 16)],                 # [JAL rd label]
    "JMPR":     [("RS1", 3)],                               # [JMPR rs1]
    "BEQ":      [("RS1", 3), ("RS2", 3), ("LABEL", 16)],    # [BEQ rs1 rs2 label]
    "BNE":      [("RS1", 3), ("RS2", 3), ("LABEL", 16)],    # [BNE rs1 rs2 label]
    "BLT":      [("RS1", 3), ("RS2", 3), ("LABEL", 16)],    # [BLT rs1 rs2 label]
    "BGE":      [("RS1", 3), ("RS2", 3), ("LABEL", 16)],    # [BGE rs1 rs2 label]
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
filename = "program2.txt"
line_count = 0

def encode(code: str, args: list[str | int]) -> None:
    print(code, args)
    instruction_val = Opcode[code] << 27 

    formats = INSTRUCTION_FORMATS[code]
    
    for arg_val, format_spec in zip(args, formats):
        field_type = format_spec[0]
        parsed_val = parse_operand(arg_val, format_spec)
        
        offset = SLOT_OFFSET[field_type]
        instruction_val |= (parsed_val << offset) # bitwise OR to combine all val

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

def make_reporter(filename, line_num, line_text):
    def fail(msg, token=""):
        col = line_text.find(token) if token else 0
        caret = "^" * len(token)
        raise SyntaxError(
            f"\nAssembly Error in '{filename}', line {line_num}:\n"
            f"  {line_text}\n"
            f"  {' ' * max(col, 0)}{caret}\n"
            f"Error: {msg}"
        )
    return fail

with open(filename, "r", encoding="utf-8") as f:
    label_name: dict[str, int] = {}
    alias: dict[str, str] = {}
    defines: dict[str, str] = {}
    line_num = 0
    temp_instructions: list[tuple[int, list[str]]] = []
    for lines in f:
        line_count += 1
        clean_line = lines.strip().split(";", 1)[0] # Remove comments
        clean_line = clean_line.strip() # strip again to remove white spaces between comment and code

        if not clean_line: # empty line
            continue

        if clean_line.endswith(":"):
            label_name[clean_line[:-1]] = line_num
            continue

        parts = re.split(r"[\s,]+", clean_line.strip()) # Accept both ADD R0 R1 and ADD R0, R1
        if parts[0] == ".alias":
            alias[parts[1]] = parts[2]
            continue

        if parts[0] == ".define":
            defines[parts[1]] = parts[2]
            continue

        temp_instructions.append((line_count, parts))
        line_num += 1

    print("Total instuctions: ", len(temp_instructions))
    print(temp_instructions)

    for line_count, temp_instruction in temp_instructions:
        opcode = temp_instruction[0]
        raw_line_text = " ".join(temp_instruction)
        args = []

        fail = make_reporter(filename, line_count, raw_line_text)

        if len(temp_instruction) - 1 != len(INSTRUCTION_FORMATS[opcode]):
            raise IndexError(f"Argument provided does not match. Needed {len(INSTRUCTION_FORMATS[opcode])}, got {len(temp_instruction) - 1} instead. Instruction: {temp_instruction}")

        for (raw_field, (field_type, width)) in zip(temp_instruction[1:], INSTRUCTION_FORMATS[opcode]):
            if field_type in ("RD", "RS1", "RS2"):
                # Reg address
                field = alias.get(raw_field, raw_field)
                if field not in Register.__members__:
                    fail(f"Opcode '{opcode}' expects a Register for {field_type}, but got '{field}'.", field)
                args.append(field)

            elif field_type in ("IMM", "BRAM"):
                field = defines.get(raw_field, raw_field)
                if field in Register.__members__:
                    fail(f"Opcode '{opcode}' expects a numeric value for {field_type}, but got Register '{field}'.", field)
                try:
                    val = int(field, 0)
                    args.append(val)
                except ValueError:
                    fail(f"Invalid numeric immediate '{field}' for {field_type}.", field)

            elif field_type == "LABEL":
                if raw_field not in label_name:
                    fail(f"Label '{raw_field}' used in '{opcode}' is not defined.", raw_field)
                args.append(label_name[raw_field])

        encode(opcode, args)

print(compiled_instruction)

with open("ex1.mem", "w", encoding="utf-8") as f:
    f.writelines(i + "\n" for i in compiled_instruction)

    print("Write complete.")