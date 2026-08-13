# CPU結構
16 bit register
32 bit instruction

# 指令集
目前打算做的指令和格式

## 指令和用法
- [ADD / SUB / MUL / DIV] R0 R1 R2: 提取存在 R0 和 R1 的值，相加，存在 R2 裡面 ; 或是要不要保留ADD R0 R1 => R0 += R1
- JMP LABEL: 把PC跳到 LABEL 去
- JNZ R0 LABEL: 如果 R0 不是 0 的話，跳到LABEL去
- HALT: 停止 CPU
- [STORE / LOAD] R0 100: 把 R0 裡的值存到 BRAM[100] 去
- LOADI R0 10: 把 10 存在 R0裡面
- MOV R0 R1: 把 R1 的值存到 R0 裡面去
- JAL R7 LABEL: 跳到 LABEL 去，並且把下一行要回來的地址直接存在 R7 裡面
- JMPR R7: 跳到 R7

- LOADR R0 R1 ; R0 = BRAM[R1]
- STORER R0 R1 ; BRAM[R1] = R0

- BEQ - branch if equal ; BEQ R0 R1 LABEL
- BNE - branch if not equal
- BLT - branch if less than
- BGE = branch if greater than or equal to

- ADDI R0 R1 1 ; R0 = R1 + 1
- SUBI R0 R1 1 ; R0 = R1 - 1

目前的修改方向和我想到的問題：
- JMP 沒辦法跳回 R7 去，因為目前 JMP 分不出來數字 / Register 地址
    - 考慮加入 JMPR (Jump Register) JMPR R7
- 也許需要固定一下指令格式：
    - 目前指令：
    - ADD   R0 R1 R2      ; R0 = R1 + R2    (dest first)
    - MOV   R0 R1         ; R0 = R1         (dest first)
    - LOADI R0 10         ; R0 = 10         (dest first)
    - JAL   R7 LABEL      ; call LABEL()    (dest first)
    這樣寫久了會很混亂


## 指令格式

[op - 5][rd - 3][rs1 - 3][rs2 - 3][imm - 16] = 30 bits

### ALU
ADD / SUB / MUL / DIV:  [op - 5][rd    - 3][rs1 - 3][rs2 - 3][empty - 16]



### imm
LOADI:                  [op - 5][rd    - 3][empty - 3][empty - 3][imm      - 16]
JMP:                    [op - 5][empty - 3][empty - 3][empty - 3][imm      - 16]
JNZ:                    [op - 5][empty - 3][rs1   - 3][empty - 3][imm      - 16]
JAL:                    [op - 5][rd    - 3][empty - 3][empty - 3][imm      - 16]


STORE / LOAD:           [op - 5][rd    - 3][empty - 3][empty - 3][BRAM adr - 16]
STORE                   [op - 5][empty - 3][rs1   - 3][empty - 3][BRAM adr - 16]
    65500: 7 segment display

JMPR:                   [op - 5][empty - 3][rs1   - 3][empty - 3][empty    - 16]

### register operations
MOV:                    [op - 5][rd    - 3][rs1   - 3][empty - 3][empty    - 16]
LOADR:                  [op - 5][rd    - 3][rs1   - 3][empty - 3][empty    - 16]

### branch if 
BEQ -                   [op - 5][empty - 3][rs1   - 3][rs2   - 3][BRAM adr - 16]
BNE -                   [op - 5][empty - 3][rs1   - 3][rs2   - 3][BRAM adr - 16]
BLT -                   [op - 5][empty - 3][rs1   - 3][rs2   - 3][BRAM adr - 16]
BGE -                   [op - 5][empty - 3][rs1   - 3][rs2   - 3][BRAM adr - 16]
ADDI -                  [op - 5][rd    - 3][rs1   - 3][empty - 3][imm      - 16]
SUBI -                  [op - 5][rd    - 3][rs1   - 3][empty - 3][imm      - 16]

HALT:                   [op - 5][empty - 3][empty - 3][empty - 3][empty    - 16]
