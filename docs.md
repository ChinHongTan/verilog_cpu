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

### ALU
ADD / SUB / MUL / DIV:  [op - 5][adr - 3][adr - 3][adr - 3]

### imm
LOADI:                  [op - 5][adr - 3][imm - 16]
JMP:                    [op - 5][empty - 3][imm - 16]
JNZ:                    [op - 5][adr - 3][imm - 16]
JAL:                    [op - 5][adr 3][imm - 16]

STORE / LOAD:           [op - 5][adr - 3][BRAM adr - 16]
    65500: 7 segment display


JMPR:                   [op - 5][adr - 3]

### 
MOV:                    [op - 5][adr - 3][adr - 3]
LOADR:                  [op - 5][addr - 3][addr - 3]

### branch if 
BEQ -                   [op - 5][adr - 3][adr - 3][BRAM adr - 16]
BNE -                   [op - 5][adr - 3][adr - 3][BRAM adr - 16]
BLT -                   [op - 5][adr - 3][adr - 3][BRAM adr - 16]
BGE -                   [op - 5][adr - 3][adr - 3][BRAM adr - 16]
ADDI -                  [op - 5][adr - 3][adr - 3][BRAM adr - 16]
SUBI -                  [op - 5][adr - 3][adr - 3][BRAM adr - 16]

HALT:                   [op - 5]





目前我們是把ALU的輸出直接接到顯示屏上
我們接下來要繼續弄的話，很大部分應該是要去增加I/O支援
與其去給每一個I/O寫指令，我們可以用一個叫memory mapped I/O的東西
就比如說，assembly我寫
STORE R0 65500
65500是隨便選的一個數字，放在後面不會跟BRAM搶地址
這個的意思就是
CPU看到了65500,他不是把R0裡面的數字接到BRAM[65500]上，而是接到顯示屏上
這樣我在軟體就可以寫STORE R0 65500
或者STORE R3 65500
相當於python裡面的print(R0)和print(R3)
這樣子我們就可以很方便的接上更多的I/O模組
比如按鈕接到65501
開關接到65502之類的

第二個概念是LOADR
LOADR R0 R1的意思就是把BRAM[R1]裡面的東西，存在R0裡面
比如我在BRAM裡面存著[1, 2, 3, 4, 5]
我要用一個loop把他們全部加起來
目前的做不到，我要寫
LOAD R0 1
LOAD R0 2
LOAD R0 3

用LOADR的話我們就可以寫

LOOP:
LOADR R0 R1
ADD R3 R3 R0
ADDI R1 R1 1 (ADDI 就是 R1 + 數字)
JNZ R2 LOOP

這樣我們就可以loop完整個BRAM
比如
LOADR R0 R1 ; R1 = 1, R0 = BRAM[R1] = BRAM[1] = 2
ADD R3 R3 R0 ; R3 = 0, R0 =2, R3 = 0 + 2 = 2
ADDI R1 R1 1 ; R1 = R1 + 1 = 1 + 1 = 2
JNZ R2 LOOP就跳回去
R1 = 2
讀BRAM[2]的資料
相加
重複