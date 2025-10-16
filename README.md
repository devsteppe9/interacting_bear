# Talking Bear Flutter App
An interactive Flutter app for kids featuring a cute polar bear character inspired by [Talking Tom](https://talkingtomandfriends.com/) and [Duolingo's Lily](https://blog.duolingo.com/ai-and-video-call/). The app creates an engaging experience where children can listen, interact, and discover exciting responses through voice conversations with their animated polar bear friend.

## Technologies

- [Rive](https://rive.app/) for smooth and resource-efficient animations including hearing, waving, and talking
- [Riverpod](https://riverpod.dev/) for state management to ensure a clean and organized codebase
- [Google Cloud Text-to-Speech AI](https://cloud.google.com/text-to-speech) for real-time text-to-speech and device's built-in speech-to-text functionalities
- [Chat GPT API](https://platform.openai.com/docs/api-reference/chat) for generating interesting and random responses

## Demo
- [Rive animation](https://rive.app/community/5628-11215-wave-hear-and-talk) used in this project.
- Live demo: [interactingbear.jackjapar.com](https://interactingbear.jackjapar.com/)
- App demo usage Video:

https://github.com/Jaha96/interacting_bear/assets/18748558/47503d50-ed7e-4050-99f8-1fc9bee3d3e0

## Requirements
- Tested with Flutter 3.35.6
- [Google Cloud API key](https://support.google.com/googleapi/answer/6158862)
- [OpenAI API key](https://help.openai.com/en/articles/4936850-where-do-i-find-my-secret-api-key)

## Getting Started

To run the project, follow these steps:

1. Check you have installed Flutter. If not, install it from [here](https://flutter.dev/docs/get-started/install).
   ```bash
   flutter --version
   ```

2. Clone project and navigate to the project directory in your terminal. 
    ```bash
    git clone https://github.com/Jaha96/interacting_bear.git
    cd interacting_bear
    ```
3. Install required dependencies.
    ```bash
    flutter pub get
    ```
4. Replace `.env.example` filename into `.env` and update your OpenAI API, Google Cloud API credentials. Example:
    ```bash
    OPENAI_API_KEY=your_openai_api_key
    GOOGLE_CLOUD_API_KEY=your_google_cloud_api_key
    ```
5. Generate Riverpod autoclasses.
    ```bash
    dart run build_runner build
    
    # or watch
    dart run build_runner watch
    ```
6. Run the app on web.
    ```bash
    flutter run -d chrome
    ```
7. Now flutter automatically opens the web browser and runs the app.

To generate launcher icons for android and ios, run the following command:
```flutter pub run flutter_launcher_icons```


I deployed this app on AWS S3 bucket and used CloudFront for CDN. And you can find CDK code for deploying this app on AWS [./cdk](https://github.com/Jaha96/interacting_bear/tree/main/cdk)


## Contribution

Contributions to this project are welcome! Feel free to create pull requests or open issues for bug fixes, feature requests, or any other improvements.

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=devsteppe9/interacting_bear&type=Date)](https://www.star-history.com/#devsteppe9/interacting_bear&Date)

## License

This project is licensed under the [MIT License](LICENSE).

---

If you have any questions or feedback, please don't hesitate to reach out to me. Happy coding!


Keywords: flutter, rive, riverpod, google-cloud-text-to-speech, chat-gpt, interactive-app, kids-app, talking-bear, animation, voice-interaction, flutter-app, flutter-project, duolingo, talking-tom, openai, flutter-web, flutter-desktop, flutter-mobile
