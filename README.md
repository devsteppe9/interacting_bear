# Talking Bear Flutter App

Welcome to the Talking Bear Flutter app! This project aims to recreate the delightful experience of the talking Tom game from our childhood using the latest technologies available to us. The app utilizes [Rive](https://rive.app/) for animations, Riverpod for state management, [Google Cloud Text-to-Speech AI](https://cloud.google.com/text-to-speech) for text-to-speech and device's built in speech-to-text functionalities, and [Chat GPT API](https://platform.openai.com/docs/api-reference/chat) for generating interesting and random responses. The primary goal is to create an interactive and cute application that listens, interacts, and generates exciting results for kids.

## Demo
Showcase some use cases and interactions of the application, highlighting the engaging and unpredictable responses from the polar bear character.
- [Rive animation](https://rive.app/community/5628-11215-wave-hear-and-talk) used in this project.
- App demo usage Video:

https://github.com/Jaha96/interacting_bear/assets/18748558/47503d50-ed7e-4050-99f8-1fc9bee3d3e0

## Requirements
- Flutter 3.10.4
- Dart 3.0.3
- [Google Cloud API key](https://support.google.com/googleapi/answer/6158862)
- [OpenAI API key](https://help.openai.com/en/articles/4936850-where-do-i-find-my-secret-api-key)

## Getting Started

To run the project, follow these steps:

1. Check you have installed Flutter. If not, install it from [here](https://flutter.dev/docs/get-started/install).
   ```bash
   flutter --version
   ```

2. Check you have installed Dart. If not, install it from [here](https://dart.dev/get-dart).
   ```bash
    dart --version
    ```
3. Clone project and navigate to the project directory in your terminal. 
    ```bash
    git clone https://github.com/Jaha96/interacting_bear.git
    cd interacting_bear
    ```
4. Install required dependencies.
    ```bash
    flutter pub get
    ```
5. Replace `.env.example` filename into `.env` and update your OpenAI API, Google Cloud API credentials. Example:
    ```bash
    OPENAI_API_KEY=your_openai_api_key
    GOOGLE_CLOUD_API_KEY=your_google_cloud_api_key
    ```
6. Generate Riverpod autoclasses.
    ```bash
    dart run build_runner build
    ```
7. Run the app on web.
    ```bash
    flutter run -d chrome
    ```
8. Now flutter automatically opens the web browser and runs the app.

To generate launcher icons for android and ios, run the following command:
```flutter pub run flutter_launcher_icons```


## Features

- Cute and interactive polar bear character with various animations like hearing, waving, and talking.
- Real-time text to speech using [Google Cloud Text-to-Speech AI](https://cloud.google.com/text-to-speech) for accurate and seamless user interactions.
- [Rive](https://rive.app/) animations for smooth and resource-efficient character movements.
- Riverpod state management to ensure a clean and organized codebase.
- [Chat GPT API](https://platform.openai.com/docs/api-reference/chat) for generating interesting and random responses, adding an element of surprise for kids.

## Language Support

The app supports both English and Japanese languages. However, for the purpose of this summit project, we will focus on the English language first.

## Contribution

Contributions to this project are welcome! Feel free to create pull requests or open issues for bug fixes, feature requests, or any other improvements.

## License

This project is licensed under the [MIT License](LICENSE).

---

Thank you for your interest in the Talking Bear Flutter app! I hope you enjoy exploring the code and interacting with my cute polar bear character. If you have any questions or feedback, please don't hesitate to reach out to us. Happy coding!
