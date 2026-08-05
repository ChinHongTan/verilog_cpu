opcode_map = {
    1: "ADD",
    2: "SUB",
    3: "MUL",
    4: "DIV",
    5: "JMP",
    6: "JNZ",
    7: "HALT",
    8: "STORE",
    9: "LOAD",
    10: "LOADI"
}

words: list[str] = []

def parse_binary_operand(operand_bits: str) -> str:
    is_register = operand_bits[0] == '1'
    val = int(operand_bits[1:], 2)  # Convert 3-bit binary to int

    if is_register:
        return "R" + str(val)
    else:
        return str(val)

with open("ex1.mem", "r", encoding="utf-8") as f:
    for line in f:
        words.append(line)

for w in words:
    opcode_val = int(w[4:8], 2)
    opcode = opcode_map[opcode_val]
    arg1_bits = w[8:12]
    arg2_bits = w[12:16]
    arg1 = parse_binary_operand(arg1_bits)
    arg2 = parse_binary_operand(arg2_bits)
    print(opcode, arg1, arg2)
