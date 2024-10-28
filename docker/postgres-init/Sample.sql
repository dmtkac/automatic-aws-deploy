CREATE SCHEMA IF NOT EXISTS sample;

CREATE TABLE IF NOT EXISTS sample."Questions" (
    id VARCHAR(50) PRIMARY KEY,
    text TEXT,
    chapterid VARCHAR(50),
    options JSONB,
    multiplecorrectanswersallowed BOOLEAN
);

CREATE TABLE IF NOT EXISTS sample."Options" (
    id VARCHAR(50) PRIMARY KEY,
    text TEXT,
    iscorrect BOOLEAN,
    questionid VARCHAR(50) REFERENCES sample."Questions"(id)
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    't1r6t1q4',
    '\[\begin{array}{ll} 4. \ Calculate: \\ \arccos ({\large-\frac{1}{2}}) + arctg (-1) - \\ - 3\arcsin {\large \frac{\sqrt{3}}{2}} \end{array}\]',
    't1r6t1',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    't1r2t2q7',
    '\[\begin{array}{ll} 7. \ In \ which \ coordinate \ quadrants \\ do \ sine \ and \ cosine \ have \ the \\ same \ signs? \end{array}\]',
    't1r2t2',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    't1r2t2q4',
    '\[\begin{array}{ll} 4. \ Arrange \ in \ descending \\ order \ the \ numbers: \\ n=\cos 125^{\circ}, \\ p=\sin 84^{\circ}, \\ m \ = \ \ tg 180^{\circ} \end{array}\]',
    't1r2t2',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r2t5q1',
    '\[\begin{array}{ll} 1. \ The \ segment \ BK \ is \ the \\ height \ of \ the \ triangle \ ABC. \\ Find \ the \ area \ of \ this \\ triangle \end{array}\] g1r2t5q1_en.png',
    'g1r2t5',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r3t2q8',
    '\[\begin{array}{ll} 8. \ Given \ a \ rhombus \\ ABCD, \ AC = 6 cm, \\ BD =  8 \ cm. \ What \\ is \ the \ cosine \ of \ angle \\ ABC? \end{array}\] g1r3t2q8_en.png',
    'g1r3t2',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r8t1q7',
    '\[\begin{array}{ll} 7. \ What \ are \ the \ coordinates \\ of \ the \ vector \ \overrightarrow{k}? \end{array}\] g1r8t1q7_en.png',
    'g1r8t1',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r8t1q4',
    '\[\begin{array}{ll} 4. \ Find \ the \ length \ of \ the \\ vector \ \overrightarrow{b} \ (-12; \ 5) \end{array}\]',
    'g1r8t1',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r7t3q6',
    '\[\begin{array}{ll} 6. \ Given \ a \ sphere \ with \ the \\ center \ O \ and \ a \ radius \ R = 5 \\ cm, \ AB \ is \ a \ tangent, \ AB = 12 \\ cm. \ Find \ the \ cosine \ of \ the \\ angle \ OBK \end{array}\] g1r7t3q6_en.png',
    'g1r7t3',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r2t1q9',
    '\[\begin{array}{ll} 9. \ The \ area \ of \ an \ equilateral \\ triangle \ is \ 1 \ cm. \ Find \ the \\ area \ of \ a \ square \ whose \ side \\ is \ equal \ to \ the \ side \ of \ the \\ given \ triangle \end{array}\]',
    'g1r2t1',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r7t3q2',
    '\[\begin{array}{ll} 2. \ The \ diameter \ of \ a \ sphere \\ is \ 5 \ cm. \ Find \ the \ surface \\ area \ of \ the \ sphere \end{array}\]',
    'g1r7t3',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r7t1q5',
    '\[\begin{array}{ll} 5. \ The \ axial \ section \ of \ the \\ cone \ is \ a \ right{-}angled \\ triangle \ with \ a \ hypotenuse \\ of \ 2\sqrt{3} \ cm. \ Find \ the \\ volume \ of \ the \ cone \end{array}\]',
    'g1r7t1',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r8t5q6',
    '\[\begin{array}{ll} 6. \ Find \ the \ difference \ of \\ the \ vectors \ \overrightarrow{SA} - \ \overrightarrow{SC} \end{array}\] g1r8t5q6_en.png',
    'g1r8t5',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r2t7q5',
    '\[\begin{array}{ll} 5. \ Triangle \ ABC \ and \ A_{1}B_{1}C_{1} \\ are \ the \ similar \ triangles, \\ AC = 12 \ cm, \ A_{1}C_{1} = 9 \ cm. \\ Find \ the \ perimeter \ of \ triangle \\ A_{1}B_{1}C_{1}, \ if \ the \ perimeter \ of \\ ABC = 36 \ cm \end{array}\]',
    'g1r2t7',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r1t3q2',
    '\[\begin{array}{ll} 2. \ In \ the \ figure \ AB = BC = \\ = CK = 5 \ cm, \ BM || CH || KO, \\ AM = 7 \ cm. \ Find \ the \ length \\ of \ HO \end{array}\] g1r1t3q2_en.png',
    'g1r1t3',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r4t5q7',
    '\[\begin{array}{ll} 7. \ The \ areas \ of \ two \ circles \ are \\ related \ as \ 4:25. \ How \ are \ the \\ radii \ related? \end{array}\]',
    'g1r4t5',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r5t2q2',
    '\[\begin{array}{ll} 2. \ Calculate \ the \ volume \ of \ a \\ regular \ triangular \ prism, \\ the \ base \ side \ of \ which \ is \ 20 \\ cm, \ and \ the \ length \ of \ the \\ lateral \ edge \ is \ 6 \ cm \end{array}\]',
    'g1r5t2',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r8t1q5',
    '\[\begin{array}{ll} 5. \ Find \ the \ value \ of \ x, \ at \\ which \ |\overrightarrow{c}| \ = 10, \ \overrightarrow{c} \ (x; -8) \end{array}\]',
    'g1r8t1',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'a1r19t2q2',
    '\[\begin{array}{ll} 2. \ The \ graph \ of \ the \ function \\ y \ = \ f(x) \ is \ shown \ in \ the \\ figure. \ Using \ the \ graph, \\ compare \ the \ derivatives \\ f''(a) \ and \ f''(b) \end{array}\] a1r19t2q2_en.png',
    'a1r19t2',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r10t1q3',
    '\[\begin{array}{ll} 3. \ From \ the \ point \ M, \ which \ lies \\ on \ one \ of \ the \ faces \ of \ the \\ dihedral \ angle, \ a \ \small perpendicular \\ MQ \ is \ drawn \ to \ the \ edge \ KN \\ and \ a \ perpendicular \ MH \ is \\ drawn \ to \ the \ other \ face. \\ Find \ the \ measure \ of \ the \\ dihedral \ angle, \ if \\ MQ = 4\sqrt{2}, \ MN = 4 \end{array}\] g1r10t1q3_en.png',
    'g1r10t1',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r3t1q1',
    '\[\begin{array}{ll} 1. \ The \ area \ of \ the \ square \\ ABCD, \ shown \ in \ the \\ figure \ is \ 14 \ {cm}^2. \ What \\ is \ the \ area \ of \ the \\ rectangle \ BMKD? \end{array}\] g1r3t1q1_en.png',
    'g1r3t1',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'a1r18t4q1',
    '\[\begin{array}{ll} 1. \ At \ which \ point \ does \ the \\ graph \ of \ the \ equation: \\ 4x \ + 5y \ = \ 20 \ intersect \ the \\ ordinate \ axis? \end{array}\]',
    'a1r18t4',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'a1r18t3q5',
    '\[\begin{array}{ll} 5. \ Find \ the \ sum \ of \ the \ zeros \\ of \ the \ function, \ shown \ in \\ the \ figure \end{array}\] a1r18t3q5_en.png',
    'a1r18t3',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'a1r16t2q3',
    '\[\begin{array}{ll} 3. \ The \ first \ pipe \ fills \ a \\ tank \ with \ a \ volume \ of \ 10 \\ cubic \ meters \ 5 \ minutes \\ faster \ than \ the \ second \ pipe. \\ How \ many \ cubic \ meters \ of \\ water \ pass \ through \ each \ pipe \\ per \ hour, \ if \ the \ first \ pipe \\ passes \ 10 \ cubic \ meters \ per \\ hour \ more \ than \ the \ second \\ pipe? \end{array}\]',
    'a1r16t2',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r7t3q5',
    '\[\begin{array}{ll} 5. \ Given \ a \ sphere \ with \ the \\ center \ O, \ AP \ is \ a \ tangent \ to \\ the \ sphere, \ and \ AP \ = \ 3 \ cm. \\ The \ radius \ of \ the \ sphere \ is \\ 4 \ cm. \ Find \ the \ length \ of \ MA \end{array}\] g1r7t3q5_en.png',
    'g1r7t3',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r2t4q4',
    '\[\begin{array}{ll} 4. \ In \ the \ isosceles \ trapezoid, \\ shown \ in \ the \ figure, \ find \\ the \ unknown \ side \ (in \ cm) \end{array}\] g1r2t4q4_en.png',
    'g1r2t4',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r8t2q5',
    '\[\begin{array}{ll} 5. \ \small Which \ pair \ of \ collinear \\ \small vectors, \ chosen \ on \ the \ given \\ \small geometric \ figures, \ will \ have \\ \small the \ ratio \ of \ corresponding \\ \small coordinates \ 2 \ : \ 1? \\ \small ABCD \ is \ square, \ KLMN \ is \\ \small \ trapezoid, \ PRF \ is \ a regular \\ \small triangle \ and \ point \ Q \ is \ a \\ \small center \ of \ the \ inscribed \ circle \end{array}\] g1r8t2q5_en.png',
    'g1r8t2',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r7t3q1',
    '\[\begin{array}{ll} 1. \ Given \ a \ sphere \ with \ center \\ O \ and \ radius \ R. \ The \ circles \\ with \ centers \ O \ and \ Q \ are \\ parallel \ sections \ of \ the \ sphere. \\ Choose \ the \ correct \ statements \end{array}\] g1r7t3q1_en.png',
    'g1r7t3',
    'null',
    true
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r8t3q3',
    '\[\begin{array}{ll} 3. \ The \ vector \ \overrightarrow{p} \ is \ the \ sum \\ of \ two \ vectors, \ shown \ in \\ the \ figure. \ Find \ these \\ vectors \end{array}\] g1r8t3q3_en.png',
    'g1r8t3',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r3t4q1',
    '\[\begin{array}{ll} 1. \ The \ line \ CM \ is \ parallel \ to \\ the \ side \ AB \ of \ the \ trapezoid \\ ABCD, \ shown \ in \ the \ figure. \\ Find \ the \ angle \ A \ of \ the \\ trapezoid \end{array}\] g1r3t4q1_en.png',
    'g1r3t4',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'a1r3t1q6',
    '\[\begin{array}{ll} 6. \ Find \ all \ valid \ values \ of \\ the \ variable \ for \ the \\ expression \ \large \frac{x}{x(|x|+1)} \end{array}\]',
    'a1r3t1',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r10t1q4',
    '\[\begin{array}{ll} 4. \ Given \ a \ cube. \ Find \ the \\ measure \ of \ the \ angle \ between \\ the \ lines \ C_{1}D \ and \ D_{1}A \end{array}\] g1r10t1q4_en.png',
    'g1r10t1',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r2t5q3',
    '\[\begin{array}{ll} 3. \ Find \ the \ area \ of \ the \\ triangle \ MPO \ (in \ cm^2 \ ) \end{array}\] g1r2t5q3_en.png',
    'g1r2t5',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'a1r11t1q7',
    '\[\begin{array}{ll} 7. \ Solve \ the \ inequality \ and \\ choose \ the \ smallest \ natural \\ solution: \\ 7 \ - \ 2x \ < \ 3x \ - \ 18 \end{array}\]',
    'a1r11t1',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r1t3q5',
    '\[\begin{array}{ll} 5. \ From \ the \ vertex \ of \ the \\ straight \ angle \ ABC = 180^{\circ}, \\ shown \ in \ the \ figure, \ rays \\ BD \ and \ BK, \ are \ drawn, \\ so \ that \ angle \ ABK = 128^{\circ}, \\ angle \ CBD \ = 164^{\circ}. \\ Calculate \ the \ measure \\ of \ angle \ DBK \end{array}\] g1r1t3q5_en.png',
    'g1r1t3',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'a1r6t5q4',
    '\[\begin{array}{ll} 4. \ Solve \ the \ equation: \\ x^2 \ - \frac{25}{49} \ = \ 0 \end{array}\]',
    'a1r6t5',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'a1r3t4q2',
    '\[\begin{array}{ll} 2. \ Perform \ the \ operation: \\ -4mn^2 \ \cdot \ \large \frac{1}{8mn} \end{array}\]',
    'a1r3t4',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'a1r10t3q3',
    '\[\begin{array}{ll} 3. \ Find \ the \ product \ of \ the \\ values \ of \ x \ and \ y, \ which \ are \\ solutions \ of \ the \ system: \\ \left\{\begin{array}{ll} 4^{\large{x+y-1}} \ = \ 32 \\ 5^{\large{2x-y-1}} \ = \ 1 \end{array}\right. \end{array}\]',
    'a1r10t3',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'g1r4t4q2',
    '\[\begin{array}{ll} 2. \ Find \ the \ degree \ measure \\ of \ the \ angle \ AOB \end{array}\] g1r4t4q2_en.png',
    'g1r4t4',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'a1r18t2q3',
    '\[\begin{array}{ll} 3. \ Find \ the \ domain \ of \ the \\ function: \ f(x) \ = \ \large\ \frac{\sqrt{x}}{x^2-1} \end{array}\]',
    'a1r18t2',
    'null',
    false
);

INSERT INTO sample."Questions" (id, text, chapterid, options, multiplecorrectanswersallowed) VALUES (
    'a1r5t3q4',
    '\[\begin{array}{ll} 4. \ How \ many \ integers \ are \ in \\ the \ given \ interval: \ \sqrt{13} \\ and \ 1? \end{array}\]',
    'a1r5t3',
    'null',
    false
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r4t5q7s1',
    '\[1 : 2\]',
    false,
    'g1r4t5q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r4t5q7s2',
    '\[4 : 25\]',
    false,
    'g1r4t5q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r4t5q7s3',
    '\[2 : 5\]',
    true,
    'g1r4t5q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r4t5q7s4',
    '\[16 : 625\]',
    false,
    'g1r4t5q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r16t2q3s4',
    '\[50 \ m^3 \ \ and \ \ 40 \ m^3\]',
    false,
    'a1r16t2q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t1q9s1',
    '\[\frac{\sqrt{3}}{3}\]',
    false,
    'g1r2t1q9'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t1q9s2',
    '\[\frac{\sqrt{3}}{2}\]',
    false,
    'g1r2t1q9'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t1q9s3',
    '\[\frac{2\sqrt{3}}{3}\]',
    false,
    'g1r2t1q9'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t1q9s4',
    '\[\frac{4\sqrt{3}}{3}\]',
    true,
    'g1r2t1q9'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t5q3s4',
    '\[28 \ cm^2\]',
    false,
    'g1r2t5q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r3t1q1s4',
    '\[14 \ cm^2\]',
    true,
    'g1r3t1q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r16t2q3s1',
    '\[30 \ m^3 \ \ and \ \ 40 \ m^3\]',
    true,
    'a1r16t2q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t1q5s1',
    '\[\sqrt{3}\pi \ cm^3\]',
    true,
    'g1r7t1q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r3t4q2s4',
    '\[-\frac{2n}{m}\]',
    false,
    'a1r3t4q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r5t3q4s1',
    '\[2\]',
    true,
    'a1r5t3q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r5t3q4s2',
    '\[3\]',
    false,
    'a1r5t3q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r5t3q4s3',
    '\[11\]',
    false,
    'a1r5t3q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r5t3q4s4',
    '\[4\]',
    false,
    'a1r5t3q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r6t5q4s4',
    '\[-\frac{7}{5}; \ \frac{7}{5}\]',
    false,
    'a1r6t5q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r10t3q3s1',
    '\[2\]',
    false,
    'a1r10t3q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r10t3q3s2',
    '\[3\]',
    true,
    'a1r10t3q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r10t3q3s3',
    '\[4.5\]',
    false,
    'a1r10t3q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r10t3q3s4',
    '\[4\]',
    false,
    'a1r10t3q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r3t1q6s1',
    '\[\begin{array}{ll}(-\infty; \ 0) \ \cup \\ (0; \ +\infty)\end{array}\]',
    false,
    'a1r3t1q6'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r3t1q6s3',
    '\[\begin{array}{ll}(-\infty; \ -1) \ \cup \\ (-1; \ +\infty)\end{array}\]',
    false,
    'a1r3t1q6'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r3t1q6s4',
    '\[\begin{array}{ll}(-\infty; \ 1) \ \cup \\ (1; \ +\infty)\end{array}\]',
    false,
    'a1r3t1q6'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r11t1q7s1',
    '\[27\]',
    false,
    'a1r11t1q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r11t1q7s2',
    '\[15\]',
    false,
    'a1r11t1q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r11t1q7s3',
    '\[6\]',
    true,
    'a1r11t1q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r11t1q7s4',
    '\[1\]',
    false,
    'a1r11t1q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q1s1',
    '\[OT \ = \ OM \ = \ R\]',
    true,
    'g1r7t3q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r18t2q3s1',
    '\[x \ \ge \ 0\]',
    false,
    'a1r18t2q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r18t2q3s2',
    '\[x \ \ge \ 0\ \ i\ \ x\neq \ 1\]',
    true,
    'a1r18t2q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r18t2q3s3',
    '\[x \ \ge \ 0\ \ i\ \ x\neq \ \pm \ 1\]',
    false,
    'a1r18t2q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r18t2q3s4',
    '\[x \ \neq \ \pm \ 1\]',
    false,
    'a1r18t2q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q1s4',
    '\[QT \ = \ OQ\]',
    false,
    'g1r7t3q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q2s1',
    '\[25\pi \ cm^2\]',
    true,
    'g1r7t3q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r18t3q5s1',
    '\[3\]',
    false,
    'a1r18t3q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r18t3q5s2',
    '\[2\]',
    false,
    'a1r18t3q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r18t3q5s3',
    '\[-1\]',
    false,
    'a1r18t3q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r18t3q5s4',
    '\[1\]',
    true,
    'a1r18t3q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r18t4q1s3',
    '\[(5; \ 0)\]',
    false,
    'a1r18t4q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r18t4q1s4',
    '\[(0; \ 2)\]',
    false,
    'a1r18t4q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r18t4q1s2',
    '\[(0; -3)\]',
    false,
    'a1r18t4q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q5s1',
    '\[3 \ cm\]',
    false,
    'g1r7t3q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r19t2q2s1',
    '\[\small Impossible \ to \ compare\]',
    false,
    'a1r19t2q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r19t2q2s4',
    '\[f''(a) \ = \ f''(b)\]',
    false,
    'a1r19t2q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r19t2q2s2',
    '\[f''(a) \ < \ f''(b)\]',
    true,
    'a1r19t2q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r19t2q2s3',
    '\[f''(a) \ > \ f''(b)\]',
    false,
    'a1r19t2q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q5s2',
    '\[6 \ cm\]',
    false,
    'g1r7t3q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q5s3',
    '\[1 \ cm\]',
    true,
    'g1r7t3q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q5s4',
    '\[9 \ cm\]',
    false,
    'g1r7t3q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q6s1',
    '\[13 \ cm\]',
    false,
    'g1r7t3q6'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r1t3q2s1',
    '\[5 \ cm\]',
    false,
    'g1r1t3q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r1t3q2s2',
    '\[8 \ cm\]',
    false,
    'g1r1t3q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r1t3q2s3',
    '\[6 \ cm\]',
    false,
    'g1r1t3q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r1t3q2s4',
    '\[7 \ cm\]',
    true,
    'g1r1t3q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r1t3q5s1',
    '\[52^{\circ}\]',
    false,
    'g1r1t3q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r1t3q5s2',
    '\[102^{\circ}\]',
    false,
    'g1r1t3q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r1t3q5s3',
    '\[146^{\circ}\]',
    false,
    'g1r1t3q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r1t3q5s4',
    '\[112^{\circ}\]',
    true,
    'g1r1t3q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t4q4s1',
    '\[1 \ cm\]',
    false,
    'g1r2t4q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t4q4s2',
    '\[6 \ cm\]',
    true,
    'g1r2t4q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t4q4s3',
    '\[3 \ cm\]',
    false,
    'g1r2t4q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t4q4s4',
    '\[2 \ cm\]',
    false,
    'g1r2t4q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t5q1s1',
    '\[66\]',
    false,
    'g1r2t5q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t5q1s2',
    '\[33\]',
    true,
    'g1r2t5q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t5q1s3',
    '\[22\]',
    false,
    'g1r2t5q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t5q1s4',
    '\[24\]',
    false,
    'g1r2t5q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t1q4s1',
    '\[79\]',
    false,
    'g1r8t1q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t1q4s2',
    '\[56\]',
    false,
    'g1r8t1q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t1q4s3',
    '\[32\]',
    false,
    'g1r8t1q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t1q4s4',
    '\[13\]',
    true,
    'g1r8t1q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t1q5s1',
    '\[1\]',
    false,
    'g1r8t1q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t1q5s2',
    '\[0\]',
    false,
    'g1r8t1q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t7q5s1',
    '\[18 \ cm\]',
    false,
    'g1r2t7q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t7q5s2',
    '\[15 \ cm\]',
    false,
    'g1r2t7q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t7q5s3',
    '\[27 \ cm\]',
    true,
    'g1r2t7q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t7q5s4',
    '\[30 \ cm\]',
    false,
    'g1r2t7q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r3t2q8s1',
    '\[0.13\]',
    false,
    'g1r3t2q8'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r3t2q8s2',
    '\[0.28\]',
    true,
    'g1r3t2q8'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r3t2q8s3',
    '\[0.74\]',
    false,
    'g1r3t2q8'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r3t2q8s4',
    '\[1.15\]',
    false,
    'g1r3t2q8'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r3t4q1s1',
    '\[40^{\circ}\]',
    false,
    'g1r3t4q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r3t4q1s2',
    '\[52^{\circ}\]',
    false,
    'g1r3t4q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r3t4q1s3',
    '\[62^{\circ}\]',
    true,
    'g1r3t4q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r3t4q1s4',
    '\[88^{\circ}\]',
    false,
    'g1r3t4q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r3t1q1s1',
    '\[12 \ cm^2\]',
    false,
    'g1r3t1q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r3t1q1s2',
    '\[16 \ cm^2\]',
    false,
    'g1r3t1q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r3t1q1s3',
    '\[10 \ cm^2\]',
    false,
    'g1r3t1q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t1q5s4',
    '\[6; -6\]',
    true,
    'g1r8t1q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r4t4q2s1',
    '\[30^{\circ}\]',
    false,
    'g1r4t4q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r4t4q2s2',
    '\[40^{\circ}\]',
    false,
    'g1r4t4q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r4t4q2s3',
    '\[26^{\circ}\]',
    false,
    'g1r4t4q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r4t4q2s4',
    '\[50^{\circ}\]',
    true,
    'g1r4t4q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t1q7s1',
    '\[(3; \ 1)\]',
    false,
    'g1r8t1q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t1q7s2',
    '\[(-1; \ 2)\]',
    true,
    'g1r8t1q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r5t2q2s1',
    '\[1200\sqrt{3}\]',
    false,
    'g1r5t2q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r5t2q2s2',
    '\[900\]',
    false,
    'g1r5t2q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r5t2q2s3',
    '\[600\sqrt{3}\]',
    true,
    'g1r5t2q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r5t2q2s4',
    '\[600\]',
    false,
    'g1r5t2q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t1q7s3',
    '\[(-3; -2)\]',
    false,
    'g1r8t1q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t1q7s4',
    '\[(4; -2)\]',
    false,
    'g1r8t1q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t3q3s1',
    '\[\overrightarrow{p} \ = \ \overrightarrow{a} \ + \ \overrightarrow{c}\]',
    false,
    'g1r8t3q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t3q3s2',
    '\[\overrightarrow{p} \ = \ \overrightarrow{b} \ + \ \overrightarrow{c}\]',
    true,
    'g1r8t3q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t3q3s3',
    '\[\overrightarrow{p} \ = \ \overrightarrow{b} \ + \ \overrightarrow{d}\]',
    false,
    'g1r8t3q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t3q3s4',
    '\[\overrightarrow{p} \ = \ \overrightarrow{a} \ + \ \overrightarrow{d}\]',
    false,
    'g1r8t3q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t5q3s1',
    '\[12 \ cm^2\]',
    false,
    'g1r2t5q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t5q3s2',
    '\[15 \ cm^2\]',
    false,
    'g1r2t5q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r2t5q3s3',
    '\[14 \ cm^2\]',
    true,
    'g1r2t5q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t1q5s3',
    '\[3\pi \ cm^3\]',
    false,
    'g1r7t1q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t1q5s4',
    '\[2\pi \ cm^3\]',
    false,
    'g1r7t1q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t2q5s2',
    '\[\overrightarrow{LM} \ and \ \overrightarrow{EH}\]',
    false,
    'g1r8t2q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t2q5s3',
    '\[\overrightarrow{AD} \ and \  \overrightarrow{HE}\]',
    false,
    'g1r8t2q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t2q5s4',
    '\[\overrightarrow{RQ} \ and \  \overrightarrow{QT}\]',
    true,
    'g1r8t2q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t5q6s1',
    '\[\overrightarrow{CA}\]',
    true,
    'g1r8t5q6'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t5q6s2',
    '\[\overrightarrow{AC}\]',
    false,
    'g1r8t5q6'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t5q6s3',
    '\[\overrightarrow{SD}\]',
    false,
    'g1r8t5q6'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t5q6s4',
    '\[\overrightarrow{SB}\]',
    false,
    'g1r8t5q6'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r16t2q3s2',
    '\[20 \ m^3 \ \ and \ \ 30 \ m^3\]',
    false,
    'a1r16t2q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r16t2q3s3',
    '\[20 \ m^3 \ \ and \ \ 10 \ m^3\]',
    false,
    'a1r16t2q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r18t4q1s1',
    '\[(0; \ 4)\]',
    true,
    'a1r18t4q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q2s2',
    '\[100\pi \ cm^2\]',
    false,
    'g1r7t3q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q2s3',
    '\[50\pi \ cm^2\]',
    false,
    'g1r7t3q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q2s4',
    '\[20\pi \ cm^2\]',
    false,
    'g1r7t3q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q1s2',
    '\[\begin{array}{ll}Triangle \ OQT \\ is \ right{-}angled\end{array}\]',
    true,
    'g1r7t3q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q1s3',
    '\[\begin{array}{ll}\small The \ circumference \ of \\ \small the \ largest \ cross- \\ \small section \ of \ a \ sphere \\ \small is \ 2\pi R^2\end{array}\]',
    false,
    'g1r7t3q1'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q6s3',
    '\[18 \ cm\]',
    false,
    'g1r7t3q6'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t2q5s1',
    '\[\overrightarrow{OA} \ and \ \overrightarrow{CO}\]',
    false,
    'g1r8t2q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t1q5s2',
    '\[\sqrt{2}\pi \ cm^3\]',
    false,
    'g1r7t1q5'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q6s2',
    '\[\frac{5}{13} \ cm\]',
    false,
    'g1r7t3q6'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r7t3q6s4',
    '\[\frac{12}{13} \ cm\]',
    true,
    'g1r7t3q6'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r3t4q2s1',
    '\[\frac{-n}{2}\]',
    true,
    'a1r3t4q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r3t4q2s2',
    '\[\frac{n}{2}\]',
    false,
    'a1r3t4q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r3t4q2s3',
    '\[\frac{2m}{n}\]',
    false,
    'a1r3t4q2'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r6t5q4s1',
    '\[\frac{25}{49}; \ - \frac{25}{49}\]',
    false,
    'a1r6t5q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r6t5q4s2',
    '\[\frac{5}{7}; \ - \frac{5}{7}\]',
    true,
    'a1r6t5q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r6t5q4s3',
    '\[\frac{5}{9}; \ \frac{9}{5}\]',
    false,
    'a1r6t5q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'a1r3t1q6s2',
    '\[\mathbb{R}\]',
    true,
    'a1r3t1q6'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r10t1q3s1',
    '\[60^{\circ}\]',
    false,
    'g1r10t1q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r10t1q3s2',
    '\[30^{\circ}\]',
    false,
    'g1r10t1q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r10t1q3s3',
    '\[45^{\circ}\]',
    true,
    'g1r10t1q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r10t1q3s4',
    '\[90^{\circ}\]',
    false,
    'g1r10t1q3'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r10t1q4s1',
    '\[60^{\circ}\]',
    true,
    'g1r10t1q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r10t1q4s2',
    '\[45^{\circ}\]',
    false,
    'g1r10t1q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r10t1q4s3',
    '\[30^{\circ}\]',
    false,
    'g1r10t1q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r10t1q4s4',
    '\[120^{\circ}\]',
    false,
    'g1r10t1q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    't1r2t2q4s1',
    '\[m; n; p\]',
    false,
    't1r2t2q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    't1r2t2q4s2',
    '\[n; m; p\]',
    false,
    't1r2t2q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    't1r2t2q4s3',
    '\[p; m; n\]',
    true,
    't1r2t2q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    't1r2t2q4s4',
    '\[m; p; n\]',
    false,
    't1r2t2q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    't1r2t2q7s1',
    '\[I; II\]',
    false,
    't1r2t2q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    't1r2t2q7s2',
    '\[II; IV\]',
    false,
    't1r2t2q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    't1r2t2q7s3',
    '\[I; III\]',
    true,
    't1r2t2q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    't1r2t2q7s4',
    '\[II; III\]',
    false,
    't1r2t2q7'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    't1r6t1q4s1',
    '\[\frac{9\pi}{4}\]',
    false,
    't1r6t1q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    't1r6t1q4s2',
    '\[\frac{3\pi}{2}\]',
    false,
    't1r6t1q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    't1r6t1q4s3',
    '\[-\frac{7\pi}{12}\]',
    true,
    't1r6t1q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    't1r6t1q4s4',
    '\[-\frac{\pi}{12}\]',
    false,
    't1r6t1q4'
);

INSERT INTO sample."Options" (id, text, iscorrect, questionid) VALUES (
    'g1r8t1q5s3',
    '\[4; -4\]',
    false,
    'g1r8t1q5'
);

