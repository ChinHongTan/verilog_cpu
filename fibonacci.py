a = 1
b = 1
c = 0

for i in range(0, 10):
    c = a
    c += b # c = a + b
    print(f" {c} ")
    a = b
    b = c