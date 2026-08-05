有異議可以直接在旁邊標註

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
- JAL LABEL R7: 跳到 LABEL 去，並且把下一行的地址直接存在 R7 裡面
- JMPR R7: 跳到 R7

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

### ALU
ADD / SUB / MUL / DIV: [op - 5][adr - 3][adr - 3][adr - 3]

### imm
LOADI: [op - 5][adr - 3][imm - 16]
JMP: [op - 5][empty - 3][imm - 16]
JNZ: [op - 5][adr - 3][imm - 16]
JAL: [op - 5][adr 3][imm - 16]

STORE / LOAD: [op - 5][adr - 3][BRAM adr - 16]

JMPR: [op - 5][adr - 3]

### RAM
MOV: [op - 5][adr - 3][adr - 3]


HALT: [op - 5]


1. JAL R7 my_function   ; Jump to "my_function", save return address in R7
2. ; [more code]

3.  my_function:
    ; [Function code goes here]
    JMP R7           ; Returns to the caller using the saved address



=======python
a = 1
b = 2

double(1)
double(2)

def double(num):
    return num + num