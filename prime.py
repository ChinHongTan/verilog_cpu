for i in range(2, 10):
    is_prime = True
    print("Turn", i)
    for j in range(2, i // 2):
        print("Check", j, "against", i // 2)
        result = i // j
        if result * j == i:
            is_prime = False
            break
    if is_prime:
        print(f"======{i} is a prime.=====")