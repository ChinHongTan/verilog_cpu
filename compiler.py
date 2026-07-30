# Input Instruction
# Output hex data

# Format: [empty - 6 bit][opcode - 4 bit][regAddr1 - 3 bit][regAddr2 - 3 bit]



from enum import IntEnum

class Opcode(IntEnum):
    ADD = 1
    SUB = 2
    MUL = 3
    DIV = 4
    MOV = 5
    JMP = 6
    JZ = 7
    HALT = 8
    WRITE = 9
    READ = 10

class Register(IntEnum):
    R0 = 1
    R1 = 2
    R2 = 3
    R3 = 4
    R4 = 5
    R5 = 6

compiled_instruction = []

with open("program.txt", "r", encoding="utf-8") as f:
    for lines in f:
        clean_line = lines.strip()
        if clean_line:
            args = clean_line.split() # ['ADD', 'R1', 'R2']
            opcode_bin = f"{Opcode[args[0]]:04b}" # 4 bit
            reg_bin_1 = f"{Register[args[1]]:03b}" # 3 bit
            reg_bin_2 = f"{Register[args[2]]:03b}" # 3 bit

            compiled_instruction.append(f"{opcode_bin}{reg_bin_1}{reg_bin_2}")

print(compiled_instruction)

with open("ex1.mem", "w", encoding="utf-8") as f:
    for i in compiled_instruction:
        f.write(i + "\n")

    print("Write complete.")