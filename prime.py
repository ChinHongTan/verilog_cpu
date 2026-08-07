for i in range(2, 10):
    is_prime = True
    for j in range(1, i // 2 + 1):
        result = i // j
        if result * j == i:
            if j == 1 or j == i:
                continue
            else:
                is_prime = False
    if is_prime:
        print(f"======{i} is a prime.=====")