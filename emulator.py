from typing import Literal

opcode_map: dict[int, str] = {
    0: "NOP",
    1:  "ADD",
    2:  "SUB",
    3:  "MUL",
    4:  "DIV",
    5:  "ADDI",
    6:  "SUBI",
    7:  "AND",
    8:  "OR",
    9:  "XOR",
    10: "NOT",
    11: "SHL",
    12: "SHR",
    13:  "MOV",
    14:  "LOAD",
    15:  "LOADI", 
    16: "LOADR", 
    17: "STORE", 
    18: "STORER",
    19: "JMP",
    20: "JNZ",
    21: "JAL",	  
    22: "JMPR",  
    23: "BEQ",
    24: "BNE",
    25: "BLT",
    26: "BGE",
    27: "HALT"
}

type DataType = Literal["RD", "RS1", "RS2", "IMM", "BRAM", "LABEL"]

INSTRUCTION_FORMATS: dict[str, list[tuple[DataType, int]]] = {
    "NOP":      [],                                         # 0 args
    "ADD":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [ADD rd rs1 rs2]
    "SUB":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [SUB rd rs1 rs2]
    "MUL":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [MUL rd rs1 rs2]
    "DIV":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [DIV rd rs1 rs2]
    "ADDI":     [("RD", 3), ("RS1", 3), ("IMM", 16)],       # [ADDI rd rs1 imm]
    "SUBI":     [("RD", 3), ("RS1", 3), ("IMM", 16)],       # [SUBI rd rs1 imm]
    "AND":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [AND rd rs1 rs2]
    "OR":       [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [OR rd rs1 rs2]
    "XOR":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [XOR rd rs1 rs2]
    "NOT":      [("RD", 3), ("RS1", 3)],                    # [NOT rd rs1]
    "SHL":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [SHL rd rs1 rs2]
    "SHR":      [("RD", 3), ("RS1", 3), ("RS2", 3)],        # [SHR rd rs1 rs2]
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

def decode(word: str) -> tuple[None | str, list[int]]:
    opcode_val = int(word[0:5], 2)
    if opcode_val not in opcode_map:
        return None, []
    opcode = opcode_map[opcode_val]
    
    formats = INSTRUCTION_FORMATS[opcode]
    operands: list[int] = []

    for field_type, width in formats:
        bit_offset = SLOT_OFFSET[field_type]
        start_idx = 32 - (bit_offset + width)
        end_idx = 32 - bit_offset

        val = int(word[start_idx:end_idx], 2)
        operands.append(val)
    
    if len(operands) != len(formats):
            raise ValueError(f"{opcode} takes {len(formats)} operands, got {len(operands)}")
    return opcode, operands

def disasm(opcode: str | None, operands: list[int]):
    if opcode is None:
        return "??? undecodable"
    parts: list[str] = []
    for (kind, _w), val in zip(INSTRUCTION_FORMATS[opcode], operands):
        match kind:
            case "RD":
                parts.append(f"R{val}")
            case "RS1":
                parts.append(f"R{val}")
            case "RS2":
                parts.append(f"R{val}")
            case "BRAM":
                parts.append("DISPLAY" if val >= 65500 else f"[{val}]")
            case "LABEL":
                parts.append(f"{val}")
            case "IMM":
                parts.append(f"{val}")

    return f"{opcode:<7}{' '.join(parts)}"

def target_of(opcode: str | None, operands: list[int]):
    if opcode in ("BEQ", "BNE", "BLT", "BGE"):
        return operands[2]
    if opcode in ("JNZ", "JAL"):
        return operands[1]
    if opcode == "JMP":
        return operands[0]
    return None

def check(program: list[tuple[str | None, list[int]]]):
    problems: list[tuple[int, str, str]] = []
    for pc, (opcode, operands) in enumerate(program):
        if opcode is None:
            problems.append((pc, "Error", "Undecodeable instruction"))
            continue
        target = target_of(opcode, operands)
        if target is None:
            continue # not a jump
        elif target >= len(program):
            problems.append((pc, "Error", f"Target {target} is past the end of program"))
        elif target == pc + 1:
            problems.append((pc, "Error", f"Jump to {target}, which is the next instruction (pc + 1). Both path leads to the same place, so the branch can never run."))

    seen:set[int] = set()
    stack = [0]
    while stack:
        pc = stack.pop()
        if pc in seen or pc >= len(program):
            continue # already seen this path / program out of bound
        seen.add(pc)
        opcode, operands = program[pc]
        if opcode == "HALT":
            continue
        elif opcode == "JMPR":
            problems.append((pc, "Info", f"Indirect jump target unresolveable. Skipping."))
            continue
        elif opcode == "JMP":
            stack.append(operands[0])
            continue # unconditional jump, only check the jump dest
        target = target_of(opcode, operands)
        if target is not None:
            stack.append(target) # check the branch, do not exit out of loop
        stack.append(pc + 1)

    for pc in range(len(program)):
        if pc not in seen:
            problems.append((pc, "Warn", "unreachable: nothing jumps or falls through to here"))
    
    return problems

reg = [0] * 8
Bram = [0] * 256  # 256 words of 32 bits each

def load():
    decoded_instructions: list[tuple[None | str, list[int]]] = []
    with open("ex1.mem", "r", encoding="utf-8") as f:
        words: list[str] = []
        for line in f:
            words.append(line)
        for w in words:
            decoded_instructions.append(decode(w))
    return decoded_instructions

step = 0
program = load()
seen_states: dict[tuple[int, tuple[int, ...]], int] = {}
outputs:list[int] = []
print("===== Disassembly =====")
for i, (o, a) in enumerate(program):
    print(f"{i:<4}{disasm(o, a)}")

print()
problems = check(program)
print("===== Program Check =====")
if problems:
    for pc, level, message in problems:
        print(f"[{level}] pc {pc}: {message}")
else:
    print("Clean")

print()
pc = 0
print("===== Run =====")
print("STEP   PC  OPCODE ARGUMENTS          EFFECTS")
while True:
    if pc >= len(program):
        print(f"\n[Stopped] PC ran off the end of the program (pc={pc}).")
        break

    if step >= 10000:
        print("Stopped because of step exceeding 10000.")
        break

    state = (pc, tuple(reg))
    if state in seen_states:
        print(f"\n[Stopped] Infinite loop: Step {step} reached the exact same state as step {seen_states[state]}.")
        print(f"          pc={pc} " + " ".join(f"R{i}={reg[i]}" for i in range(8)))
        break
    seen_states[state] = step
    opcode, args = program[pc]
    pc += 1
    note = ""
    before = reg.copy()

    match opcode:
        case "NOP":
            pass

        case "ADD":
            result = reg[args[1]] + reg[args[2]]
            if result > 65535:
                note = f"  <-- overflow, {result} wraps to {result & 65535}"
            reg[args[0]] = result & 65535
            
        case "SUB":
            result = reg[args[1]] - reg[args[2]]
            if result < 0:
                note = f"  <-- underflow, {result} wraps to {result & 65535}"
            reg[args[0]] = result & 65535
            
        case "MUL":
            result = reg[args[1]] * reg[args[2]]
            if result > 65535:
                note = f"  <-- overflow, {result} wraps to {result & 65535}"
            reg[args[0]] = result & 65535
            
        case "DIV":
            if reg[args[2]] == 0:
                note = f"  <-- Division by zero!"
                break
            reg[args[0]] = (reg[args[1]] // reg[args[2]]) & 65535

        case "ADDI":
            result = reg[args[1]] + args[2]
            if result > 65535:
                note = f"  <-- overflow, {result} wraps to {result & 65535}"
            reg[args[0]] = result & 65535

        case "SUBI":
            result = reg[args[1]] - args[2]
            if result < 0:
                note = f"  <-- underflow, {result} wraps to {result & 65535}"
            reg[args[0]] = result & 65535

        case "AND":
            result = reg[args[1]] & reg[args[2]]
            reg[args[0]] = result & 65535

        case "OR":
            result = reg[args[1]] | reg[args[2]]
            reg[args[0]] = result & 65535

        case "XOR":
            result = reg[args[1]] ^ reg[args[2]]
            reg[args[0]] = result & 65535

        case "NOT":
            result = ~reg[args[1]]
            reg[args[0]] = result & 65535

        case "SHL":
            result = reg[args[1]] << reg[args[2]]
            reg[args[0]] = result & 65535

        case "SHR":
            result = reg[args[1]] >> reg[args[2]]
            reg[args[0]] = result & 65535
            
        case "MOV":
            reg[args[0]] = reg[args[1]]
            
        case "LOAD": # BRAM
            reg[args[0]] = Bram[args[1]]
            
        case "LOADI":
            reg[args[0]] = args[1]
            
        case "LOADR": # BRAM
            reg[args[0]] = Bram[args[1]]
            
        case "STORE": # BRAM
            if args[1] >= 65500:
                outputs.append(reg[args[0]])
                note += f"OUTPUT: {reg[args[0]]}"
            else:
                Bram[args[1]] = reg[args[0]]

        case "STORER":
            Bram[args[1]] = reg[args[0]]
            
        case "JMP":
            pc = args[0]
            
        case "JNZ":
            note = f"  [R{args[0]}={reg[args[0]]} -> {'taken' if reg[args[0]] != 0 else 'fall through'}]"
            if reg[args[0]] != 0:
                pc = args[1]
            
        case "JAL":
            reg[args[0]] = pc # pc already incremented in fetch
            pc = args[1]
            
        case "JMPR":
            pc = reg[args[0]]
            
        case "BEQ":
            note = f"  [R{args[0]}={reg[args[0]]} -> {'taken' if reg[args[0]] == reg[args[1]] else 'fall through'}]"
            if reg[args[0]] == reg[args[1]]:
                pc = args[2]
            
        case "BNE":
            note = f"  [R{args[0]}={reg[args[0]]} -> {'taken' if reg[args[0]] != reg[args[1]] else 'fall through'}]"
            if reg[args[0]] != reg[args[1]]:
                pc = args[2]           
            
        case "BLT":
            note = f"  [R{args[0]}={reg[args[0]]} -> {'taken' if reg[args[0]] <  reg[args[1]] else 'fall through'}]"
            if reg[args[0]] <  reg[args[1]]:
                pc = args[2]
            
        case "BGE":
            note = f"  [R{args[0]}={reg[args[0]]} -> {'taken' if reg[args[0]] >= reg[args[1]] else 'fall through'}]"
            if reg[args[0]] >= reg[args[1]]:
                pc = args[2]
            
        case "HALT":
            break
    changed: list[str] = []
    for i in range(8):
        if reg[i] != before[i]:
            changed.append(f"R{i}:{before[i]}->{reg[i]}")
    
    # debug
    print(f"{step:>4}  {pc:>3}  {disasm(opcode, args):<24}  {" ".join(changed)}  {note}")
    step += 1

print(f"Outputs: {outputs}")