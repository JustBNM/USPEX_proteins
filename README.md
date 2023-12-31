# USPEX_proteins

Предсказание третичной структуры белка на основе первичной аминокислотной последовательности с помощью генетического алгоритма USPEX.

Поддерживает все потенциалы, указанные в папке forcefields. Рекомендуемые потенциалы - amber99sb.prm, charmm22cmap.prm

Содержимое:
 - FunctionFolder - рабочий код USPEX для расчётов
 - Specific - информация о том белке, который мы оптимизируем в текущий момент, и условия оптимизации
 - Submission - код для отправки процесса оптимизации белков на кластер
 - forcefields - набор потенциалов
 - INPUT.txt - конфигурация расчётов USPEX
 - USPEX.m - стартовая точка расчёта, которая запускает единичный шаг оптимизации
 - sbatch_script - скрипт для отправки множественного запуска USPEX.m на кластер

Для детальной информации по содержанию INPUT.txt изучите [соответствующие главы мануала USPEX](https://uspex-team.org/online_utilities/uspex_manual_release/EnglishVersion/uspex_manual_english/inputs.html)
## Запуск
Единичный ручной запуск:

`matlab < USPEX.m`

Полный запуск расчёта белка на все поколения:
`sbatch sbatch_script` (рекомендуемый способ) - отправит sbatch_script на одну из нод, с которой будут идти отдельные запуски USPEX.m\
`nohup ./sbatch_script &` - если вы хотите, чтобы sbatch_script крутился локально (расчёты отдельных минимизаций всё ещё будут идти удаленно, если это указано в поле whichCluster файла INPUT.txt)

Очистка рабочей директории после завершения расчётов:\
`USPEX --clean`\
Удалит все промежуточные рабочие файлы, связанные с расчётом (в первую очередь CalcFold). Оставляет файлы указанные выше + директорую с результатами расчёта.


## Важно
Перед началом работы необходимо указать путь к директории со структурами реальных белков (DB):
1. Расположите директорию в удобной для вас месте.
2. В файле FunctionFolder/USPEX/M400/Random_Init_M400.m на 32 строке `folder=['<INSERT YOUR ABSOLUTE PATH TO DB>/' num2str(which_res) '_res'];`, укажите вместо заглушки путь до вашей директории.
3. Результат может выглядеть так: `folder=['/home/prachitskiy/DB/' num2str(which_res) '_res'];`
4. Вы великолепны и готовы запускаться.

### Specific
Файлы специфичные для каждого конкретного белка.

__Содержимое:__
1. <имя потенциала>.pdb (например amber.pdb)\
Содержит файл с третичной структорой белка, взятой из базы данных PDB. Данная структура была проведенна через минимизацию в выбранном потенциале, чтобы учесть его особенности. Относительно этой структуры считается RMSD всех структур, получаемых в ходе работы алгоритма.
2. <имя потенциала>.prm (например amber99sb.prm)\
Файл с самим потенциалом
3. input.key_1\
Файл, определяющий потенциал и тип водного окружения, используемые в рамках оптимизации.
4. input.make0_1\
Файл, определяющий первичную аминокислотную последовательность белка и начальную его конформацию.\
Формат:
```
input
<имя белка/любая строка>
<аминокислота 1> <угол фи> <угол пси> <угол омега>
tyr   0.002  -0.002  180
...

trp   0.009  -0.009  180

n
```

### INPUT.txt
Ещё раз дам ссылку на [мануал USPEX](https://uspex-team.org/online_utilities/uspex_manual_release/EnglishVersion/uspex_manual_english/inputs.html).
Из наиболее важного:

`5   : populationSize` - размер каждой популяции\
`5   : initialPopSize` - размер начальной популяции\
`5   : numGenerations` - число поколений\
`5    : stopCrit` - количество поколений, в течении которых не должно меняться лучшее значение фитнесс функции, чтобы вычисление закончилось досрочно.



Вариационные операторы и доля структур, к которым они применяются:
```
0.3   : fracRand
0.23   : fracGene
0.22   : fracRotMut
0.10   : fracSecSwitch
0.15   : fracShiftBorder
```
Количество атомов в белка:
```
% numSpecies
10
```
`5    : numParallelCalcs` - Количество параллельных вычислений индивидумов. \
`7     : whichCluster` - На каком кластере идёт расчёт. 7 для Рюрика. 


### Расчёт нового белка
Когда требуется оптимизировать <ins>новый белок</ins> в этом же потенциале - заменяться файлы `input.make0_1`, куда прописывается аминокислотная последовательность нового белка, и `<имя потенциала>.pdb`, куда кладется истинная структруа. Меняется количество атомов в поле `numSpecies` файла `INPUT.txt`\
Когда требуется оптимизировать белок в <ins>новом потенциале</ins> - меняются файлы `<имя потенциала>.prm` и `input.key_1`, где прописывается имя потенциала.

Другие папки/файлы менять не требуется 
   
