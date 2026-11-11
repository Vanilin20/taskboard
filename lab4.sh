#!/usr/bin/env bash
# Лабораторна 4. Git у терміналі — Оліферук Іван, ІПЗ-3/1
# Запуск у Git Bash із папки taskboard:   bash lab4.sh
set -e

# ---------- Крок 1. Перевірка Git ----------
# Глобальні налаштування НЕ чіпаємо: ім'я/пошта задаються лише для цього репозиторію (після git init)
git --version
NAME="Іван Оліферук"
EMAIL="oliferukivan19@gmail.com"

# Перевірка, що ми в правильній папці
[ -f index.html ] || { echo "Нема index.html — зайди в папку taskboard (cd /c/webdev/taskboard)"; exit 1; }
grep -q "<h1>TaskBoard</h1>" index.html || { echo "В index.html нема рядка <h1>TaskBoard</h1> — додай його в <body>"; exit 1; }
[ -d .git ] && { echo "Тут уже є .git — видали його (rm -rf .git), якщо хочеш почати з нуля"; exit 1; }

# about.html з лаби 2 відкладаємо поруч із папкою — у кроці 5 він має з'явитись у гілці about-page
if [ -f about.html ]; then
  mv about.html ../about_lab2_backup.html
  echo "about.html з лаби 2 перенесено в ../about_lab2_backup.html"
fi
# report.md потрібен для кроку 3 і 7 (звіт лаби 2 у тебе в PDF)
[ -f report.md ] || printf "# Звіти з веб-розробки\nОліферук Іван, ІПЗ-3/1\n" > report.md

# ---------- Крок 2. Репозиторій ----------
git init -b main                   # гілка main без зміни глобального init.defaultBranch
git config user.name  "$NAME"      # без --global: тільки для taskboard
git config user.email "$EMAIL"
git config core.quotepath false    # кирилиця в status/log без \320\224...
git config --local --list | grep -E "user\.|quotepath"
git status
ls -a

# ---------- Крок 3. Перший commit ----------
printf "Thumbs.db\n.DS_Store\n*.log\n" > .gitignore
git add index.html
git status
git commit -m "Додати головну сторінку"
git add .
git commit -m "Додати логотип, звіт і .gitignore"
git --no-pager log
git --no-pager log --oneline

# ---------- Крок 4. Зміни та diff ----------
sed -i 's|</body>|<p>TaskBoard допоможе керувати завданнями команди.</p>\n</body>|' index.html
git status
git --no-pager diff
sed -i 's|</body>||' index.html          # «помилка»: видалили </body>
git restore index.html                   # повернули стан останнього commit (абзац теж зник)
sed -i 's|</body>|<p>TaskBoard допоможе керувати завданнями команди.</p>\n</body>|' index.html
git add index.html
git commit -m "Додати опис проєкту на головну"

# ---------- Крок 5. Гілки та злиття ----------
git switch -c about-page
git branch
cat > about.html <<'EOF'
<!DOCTYPE html>
<html lang="uk">
<head>
 <meta charset="UTF-8">
 <title>Про проєкт</title>
</head>
<body>
 <h1>Про TaskBoard</h1>
 <p>TaskBoard: дошка завдань, яку ми будуємо на курсі.</p>
 <a href="index.html">На головну</a>
</body>
</html>
EOF
git add about.html
git commit -m "Додати сторінку про проєкт"
git switch main
ls
git merge about-page
git branch -d about-page
git --no-pager log --oneline

# ---------- Крок 6. Конфлікт ----------
git switch -c ukr-title
sed -i 's|<h1>TaskBoard</h1>|<h1>Дошка завдань</h1>|' index.html
git add index.html
git commit -m "Перекласти заголовок українською"

git switch main
sed -i 's|<h1>TaskBoard</h1>|<h1>TaskBoard: керуй завданнями</h1>|' index.html
git add index.html
git commit -m "Розширити заголовок"

git merge ukr-title || true              # тут буде CONFLICT
git status
echo "----- index.html з конфліктом -----"
cat index.html
echo "-----------------------------------"
# Розв'язання: блок <<<<<<< ... >>>>>>> замінюємо одним рядком
sed -i '/^<<<<<<< /,/^>>>>>>> /c\<h1>Дошка завдань: керуй завданнями</h1>' index.html
git add index.html
git commit -m "Об'єднати варіанти заголовка"
git branch -d ukr-title
git --no-pager log --oneline --graph

# ---------- Додаткове завдання ----------
git switch -c experiment
echo "зламано" > index.html
git commit -am "Зламати головну (експеримент)"
git switch main
git branch -D experiment
head -n 3 index.html                     # main не постраждав
git --no-pager log --oneline -- index.html

# ---------- Крок 7. Звіт ----------
LOG=$(git --no-pager log --oneline)
COUNT=$(git rev-list --count HEAD)
cat >> report.md <<EOF

## Лабораторна 4. Git у терміналі

1. **Що змінилося у виводі git status після git add?** Файл перейшов зі списку Untracked (червоний) у Changes to be committed (зелений), тобто потрапив в індекс і буде збережений наступним commit-ом.
2. **Що показує git diff?** Різницю між робочою папкою та індексом: рядки з «+» додані, з «-» видалені.
3. **Чим відрізняється git switch main від git merge?** git switch лише перемикає на іншу гілку і змінює файли в папці під неї, а git merge переносить (вливає) commit-и з іншої гілки в поточну.
4. **Чому виник конфлікт і як я його розв'язав?** У гілках main та ukr-title по-різному змінили той самий рядок із <h1>, тож Git не зміг сам вибрати варіант. Я поєднав обидва варіанти в «Дошка завдань: керуй завданнями», видалив службові рядки <<<<<<<, =======, >>>>>>>, зробив git add і commit.
5. **Скільки commit-ів в історії?** $COUNT (до цього звітного commit-у), вивід git log --oneline:

\`\`\`
$LOG
\`\`\`
EOF
git add report.md
git commit -m "Додати звіт до лабораторної 4"

echo
echo "===== Показати викладачу ====="
git --no-pager log --oneline --graph
