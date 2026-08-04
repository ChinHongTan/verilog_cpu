# Input Instruction
# Output bin data

# Format: [empty - 4 bit][opcode - 4 bit][regAddr1 - 4 bit][regAddr2 - 4 bit]

from enum import IntEnum

class Opcode(IntEnum):
    ADD = 1
    SUB = 2
    MUL = 3
    DIV = 4
    JMP = 5
    JZ = 6          # Jump if the register is zero, e.g. JZ R3 ADD_SECTION
    HALT = 7
    STORE = 8       # Save to RAM
    LOAD = 9
    LOADI = 10      # Save to register with an immediate number, e.g. LOADI R0 2

class Register(IntEnum):
    R0 = 1
    R1 = 2
    R2 = 3
    R3 = 4
    R4 = 5
    R5 = 6

compiled_instruction = []

def encode(code, arg2, arg3):
    print(code, arg2, arg3)
    empty_bin = f"{0:04b}" # 4 empty bit
    opcode_bin = f"{Opcode[code]:04b}" # 4 bit

    reg_bin_1 = parse_operand(arg2) # 3 bit
    reg_bin_2 = parse_operand(arg3) # 3 bit

    compiled_instruction.append(f"{empty_bin}{opcode_bin}{reg_bin_1}{reg_bin_2}")

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
    label_name = {}
    line_num = 0
    for lines in f:

        clean_line = lines.strip()
        if not clean_line:
            continue

        if clean_line.endswith(":"):
            label_name[clean_line[:-1]] = line_num
            continue

        line_num += 1

    f.seek(0)

    for lines in f:
        arg2 = 0
        arg3 = 0
        clean_line = lines.strip()
        print(clean_line)
        if not clean_line:
            continue

        if clean_line.endswith(":"):
            continue

        args = clean_line.split() # ['ADD', 'R1', 'R2']

        if args[0] == 'JZ':
            print("Label name:", label_name)
            arg2 = args[1]
            arg3 = label_name.get(args[2], None)
            if not arg3:
                raise ValueError(f"Label {args[2]} not found.")
        elif args[0] == 'JMP':
            arg2 = label_name.get(args[1], None)
            if not arg2:
                raise ValueError(f"Label {args[1]} not found.")
        elif args[0] != 'HALT':
            arg2 = args[1]
            arg3 = args[2]

        print("Encoding:", args[0], arg2, arg3)
        encode(args[0], arg2, arg3)

print(compiled_instruction)

with open("ex1.mem", "w", encoding="utf-8") as f:
    for i in compiled_instruction:
        f.write(i + "\n")

    print("Write complete.")