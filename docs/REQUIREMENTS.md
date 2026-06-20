---

title: DIMA - Exam Requirements 
tags:

- dima
- polimi
- exam

---

# DIMA — Exam Requirements (2025/2026)

## 1 · Team & Proposal

- **Team**: exactly 3 people (exceptions only with a strong motivation)
- **Project proposal**: email to the professor **no earlier than mid-November**
    - Own idea (recommended) or company-proposed project (Bending Spoons, Luxottica, TreNord, WHO…)
    - The professor replies accepting/rejecting (in practice he always accepts)
- **Publishing forbidden** on app stores before passing the exam

## 2 · Idea Constraints

|Constraint|Details|
|---|---|
|Originality|The app must not already exist on the market or copy existing apps|
|No recycling|Previously developed projects cannot be reused|
|No social networks|Explicitly forbidden|
|No map apps|Explicitly forbidden|
|No cost-splitting / flatmate apps|Explicitly forbidden|
|No business-related apps|From the professor's slides|

## 3 · Technical Requirements

### 3.1 Complexity

- The app must be **significantly complex**: multiple screens, articulated application flow
- Appropriate use of data
- **Multiple threads** management

### 3.2 External Services

- At least **one external service beyond Firebase**
- Authentication + storage alone are **not enough** → interaction with at least one additional API is required
- External ML/AI systems are encouraged but not evaluated on their technical merit

### 3.3 Multi-device & UI

- **Two distinct layouts**: one for small screens (phone), one for large screens (tablet+)
- The app must correctly adapt to **screen rotation**
- Polished UI/UX: professional and appealing look and feel
- First impression is key: minimal help text, intriguing design

### 3.4 Sensors (optional)

Accelerometer · Gyroscope · Digital compass · GPS · Barometer · Ambient light · Proximity sensor

## 4 · Allowed Languages

|Language|Platform|Notes|
|---|---|---|
|Flutter|Cross-platform|Material or Cupertino are enough; `go_router` for navigation; multilanguage not required (`i18n` optional)|
|React Native|Cross-platform|—|
|Swift|iOS only|—|
|Java / Kotlin|Android only|—|

> [!info] No penalty for choosing one language over another.

> [!tip] ChatGPT You can use ChatGPT for development, as long as you can **explain everything** in the produced code.

## 5 · Test Campaign

- Order of magnitude: **hundreds** of tests (not thousands, not four)
- Test classes inside the `test/` folder of the project

## 6 · Documentation

> [!warning] Design/Test Document (PDF)
> 
> - It is **not** a user manual
> - Do **not** show screen screenshots
> - It must explain the **software design** and include the **test campaign**

## 7 · Presentation & Exam

|Element|Details|
|---|---|
|Duration|**10–12 minutes** total|
|Content|Introduction + design elements (technical presentation, oriented to "sell" the product)|
|Demo|**Live** on real device or simulator (no recorded videos)|
|Q&A|Answers to the professor's questions (if any)|
|Mode|**In person** (online only with a strong motivation)|
|Dates|Only on **official exam dates** (no exceptions)|

## 8 · Evaluation Criteria

1. Novelty of the idea
2. App complexity (screens + functionality)
3. External services used (beyond auth/storage)
4. Look and feel
5. Multi-device support
6. Test campaign
7. Design/Test document
8. Presentation quality