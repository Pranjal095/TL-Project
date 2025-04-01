# Math DDR Simulator

A gamified math learning experience that combines Dance Dance Revolution (DDR) gameplay with math problems.

## Overview

Math DDR Simulator is an educational game that helps players practice basic math skills in a fun, engaging way. Players solve math problems by hitting arrow keys that match the correct answer.

## Features

- **Multiple Difficulty Levels**: Choose from Easy, Medium, or Hard difficulty levels.
- **Adaptive Math Problems**: 
  - Easy: Single-digit addition and multiplication
  - Medium: Two-digit arithmetic with all operations (addition, subtraction, multiplication, division)
  - Hard: Three-digit arithmetic with all operations
- **Dynamic Gameplay**: Increasing speed based on performance and combo
- **Visual Feedback**: Instant feedback on answers with hit ratings
- **Performance Tracking**: Score, combo counter, and skill rating system
- **Background Music**: Customizable audio volume controls

## Controls

- **W Key**: Hit up arrow
- **A Key**: Hit left arrow
- **S Key**: Hit down arrow
- **D Key**: Hit right arrow
- **ESC Key**: Return to start screen

## How to Play

1. Select your difficulty level from the start screen
2. Observe the math problem at the top of the screen
3. Look for arrows with numbers that match the correct answer
4. Press the corresponding key when the arrow reaches the target zone
5. Perfect timing gives more points
6. Build combos by hitting consecutive correct answers
7. Watch your skill rating increase as you improve

## Installation & Running the Project

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (2.0 or newer)
- [Git](https://git-scm.com/downloads)
- A code editor (like VS Code, Android Studio, etc.)

### Clone & Run
1. Clone the repository:
   ```
   git clone https://github.com/yourusername/TL-Project.git
   cd TL-Project
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Make sure you have all assets in place:
   - Create an `assets` folder in the root directory if it doesn't exist
   - Add a background video named `dance.mp4` to the assets folder

4. Update `pubspec.yaml` to include assets:
   ```yaml
   flutter:
     assets:
       - assets/dance.mp4
   ```

5. Run the app:
   ```
   flutter run
   ```
   
   For web:
   ```
   flutter run -d chrome
   ```

### Troubleshooting
- If you encounter issues with missing packages, run `flutter pub get` again
- For platform-specific issues, refer to the [Flutter documentation](https://flutter.dev/docs)
- Check that all assets are correctly referenced in the pubspec.yaml file

## Development

This project is built using Flutter, making it compatible across multiple platforms. The game includes:

- Custom animations and visual effects
- Video background integration
- Responsive design for various screen sizes
- Mathematics engine that generates appropriate problems based on difficulty

## Project Structure

- `lib/main.dart` - Application entry point
- `lib/screens/` - Contains main game screens
  - `start_screen.dart` - Initial screen with difficulty selection
  - `ddr_simulator_screen.dart` - Main gameplay screen
- `lib/models/` - Data models
- `lib/widgets/` - Reusable UI components

## Future Enhancements

- Additional math operations and problem types
- Customizable themes and animations
- Multiplayer mode
- High score leaderboard
- More detailed performance analytics

## Credits

- Developed as an educational project
- Music and visual assets used under appropriate licenses
