from emulator import INSTRUCTION_FORMATS, load

def make_bag(pc, opcode, operands):
    fields = dict(zip([k for k, _ in INSTRUCTION_FORMATS[opcode]], operands))
    return {
        "pc": pc,
        "op": opcode,
        "rd":  fields.get("RD"),
        "rs1": fields.get("RS1"),
        "rs2": fields.get("RS2"),
        "imm": fields.get("IMM") or fields.get("BRAM") or fields.get("LABEL"),
        "we":  "RD" in fields,        # does this instruction write a register?
    }

decode = execute = memory = writeback = None
pc = 0
program = load()

for i in range(6):
    new_decode = make_bag(pc, *program[pc]) if pc < len(program) else None
    pc += 1
    new_execute   = decode
    new_memory    = execute
    new_writeback = memory

    decode, execute, memory, writeback = new_decode, new_execute, new_memory, new_writeback
    print(f"cyc {i}:\n            ID={decode}\n            EX={execute}\n            MEM={memory}\n            WB={writeback}")
