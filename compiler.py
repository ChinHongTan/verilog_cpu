# Input Instruction
# Output bin data

# Format: [empty - 4 bit][opcode - 4 bit][regAddr1 - 4 bit][regAddr2 - 4 bit]

from enum import IntEnum

class Opcode(IntEnum):
    ADD = 1
    SUB = 2
    MUL = 3
    DIV = 4
    MOV = 5
    JMP = 6
    JZ = 7          # Jump if the register is zero, e.g. JZ R3 ADD_SECTION
    HALT = 8
    STORE = 9       # Save to RAM
    LOAD = 10
    LOADI = 11      # Save to register with an immediate number, e.g. LOADI R0 2

class Register(IntEnum):
    R0 = 1
    R1 = 2
    R2 = 3
    R3 = 4
    R4 = 5
    R5 = 6

compiled_instruction = []

def parse_operand(arg: str) -> str:
    # Try as Register
    if arg in Register.__members__:
        reg_val = Register[arg].value
        return f"1{reg_val:03b}"

    try:
        num = int(arg)
        if not (0 <= num <= 7):
            raise ValueError(f"Immediate value {num} out of range.")
        return f"0{num:03b}"
    except ValueError as e:
        raise ValueError(f"Invalid operand {arg}: must be a valid Register or number.") from e

with open("program.txt", "r", encoding="utf-8") as f:
    for lines in f:
        clean_line = lines.strip()
        if not clean_line:
            continue

        args = clean_line.split() # ['ADD', 'R1', 'R2']
        empty_bin = f"{0:04b}" # 4 empty bit
        opcode_bin = f"{Opcode[args[0]]:04b}" # 4 bit

        reg_bin_1 = parse_operand(args[1]) # 3 bit
        reg_bin_2 = parse_operand(args[2]) # 3 bit

        compiled_instruction.append(f"{empty_bin}{opcode_bin}{reg_bin_1}{reg_bin_2}")

print(compiled_instruction)

with open("ex1.mem", "w", encoding="utf-8") as f:
    for i in compiled_instruction:
        f.write(i + "\n")

    print("Write complete.")