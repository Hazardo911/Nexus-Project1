# Nexus-Project1
AI-powered fitness coach that detects incorrect exercise form using pose estimation and provides real-time feedback
AI Fitness Coach (a.k.a. “bhai form sahi rakh” system)
🧠 What is this?
This is our attempt at building an:
🏋️ AI-based exercise form correction system
Basically:
Plain text
Camera → Skeleton → Maths → “bhai seedha khada reh”
🎯 What we TRIED to do
According to the problem statement:
detect incorrect form ✅
analyze movement ✅
give feedback ✅
and also (unnecessarily):
classify exercise using AI model 🤡
🧩 Project Structure (aka what file does what)

realtime.py        → camera + UI + everything running live
engine.py          → counts reps, tracks session, handles logic
exercise_logic.py  → actual brain (angles + feedback)
main.py            → FastAPI backend (start/stop system)
model.pth          → “AI” that sometimes guesses correctly
label_map.json     → translates model output to human words
🔥 The REAL HERO
💥 exercise_logic.py
This is where the magic happens.
knee angle
back posture
symmetry
depth
👉 basically replaced gym trainer
⚙️ engine.py
counts reps
decides good vs bad
gives accuracy
handles goal
👉 silent worker, no drama
🎥 realtime.py
camera
pose detection
UI
feedback
👉 this is what user sees
🌐 main.py
FastAPI backend
can start/stop system
👉 we added it because… backend hona chahiye 😎
🤖 The “AI Model” Story (important 😭)
We trained a model (.pth) to:
Plain text
detect which exercise user is doing
Sounds cool right?
Yeah… about that…
💀 Reality
Model does things like:
Plain text
Squat → benchpress 🤡
Jumping jack → squat 😭
Confidence → 0.3 (bas guess maar raha hai)
🧠 Why this happened
training data ≠ real-world data
camera angle issues
similar motion patterns
model is lightweight
🧪 What we learned
Model is not the hero.
Maths + logic is.
🔥 What we did instead
We did NOT delete the model (because ego 😤)
But:
Plain text
Model → suggestion only
Logic → actual system
🏆 Final System (actual working thing)
Plain text
User selects exercise
↓
Camera tracks movement
↓
System checks:
- angle
- posture
- symmetry
↓
Feedback:
“Go lower”
“Knees inward ❌”
“Good form ✅”
↓
Final:
Accuracy + summary
📊 Features
✅ real-time tracking
✅ multi-exercise support
✅ rep counting
✅ form correction
✅ symmetry detection
✅ feedback system
✅ goal tracking
✅ session summary
⚠️ Problems we faced (aka trauma log)
model predicting random things
lag due to input + UI mix
typing errors (jumping jacks vs jumpingjack)
frame mismatch (40 vs 100)
confidence issues
mental breakdown 👍
🧠 Key realization
Plain text
AI ≠ always deep learning
Sometimes:
Plain text
if knee angle wrong → shout at user
👉 is better AI
🏃 How to run
Install stuff:
Bash
pip install fastapi uvicorn opencv-python mediapipe numpy torch
Run backend:
Bash
uvicorn main:app --reload
Go to:
Plain text
http://127.0.0.1:8000/docs
Hit:

POST /start
🧪 Before changing anything
Please:
👉 run once
👉 see how it works
Then break it 👍

Final note
We wanted to do more…
but body said:
Plain text
“bhai bas kar”
Still:
👉 system works
👉 logic is strong
👉 demo is solid


integrated the backend with ai however the model was still not working because of which backend code and logic also got sacrificed so what i did was relied heavily on code and maths for model to look good rather than ai most of the code in this is written and discussed with ai to make this deadline ready if anybody has any better idea then they are free to make changes if not but also check how mine works maybe install fastapi uvicorn and run uv sync and then uvicorn main:app --reload and check post /start in swagger once before doing any changes bohot bimar hu aur mehnat kar sakta tha ispe but nahi ho raha abhi kuch isme we are doomed in this
