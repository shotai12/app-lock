def warikan(total, people):
    return total / people

total = int(input("合計金額を入力してください: "))
people = int(input("人数を入力してください: "))

result = warikan(total, people)
print(f"一人あたり {result:.0f} 円です")
