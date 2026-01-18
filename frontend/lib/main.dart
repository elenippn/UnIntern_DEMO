import 'package:flutter/material.dart';
import 'screens/loadscreen.dart';
import 'screens/signup_screen.dart';
import 'screens/signup_student_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/home_student_screen.dart';
import 'screens/newpost_student_screen.dart';
import 'screens/search_student_screen.dart';
import 'screens/messages_student_screen.dart';
import 'screens/message_chat_screen.dart';
import 'screens/profile_student_screen.dart';
import 'screens/profile_edit_student_screen.dart';
import 'screens/add_file_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/saved_listings_student_screen.dart';
import 'screens/signup_company_screen.dart';
import 'screens/home_company_screen.dart';
import 'screens/messages_company_screen.dart';
import 'screens/message_chat_company_screen.dart';
import 'screens/profile_company_screen.dart';
import 'screens/profile_edit_company_screen.dart';
import 'screens/newpost_company_screen.dart';
import 'screens/search_company_screen.dart';
import 'screens/add_file_company_screen.dart';
import 'screens/camera_company_screen.dart';
import 'screens/saved_listings_company_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UnIntern',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFAFD9F)),
        useMaterial3: true,
        fontFamily: 'Trirong',
      ),
      home: const LoadScreen(),
    
      routes: {
        '/loadscreen': (context) => const LoadScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/signup_student': (context) => const SignUpStudentScreen(),
        '/signin': (context) => const SignInScreen(),
        '/home_student': (context) => const HomeStudentScreen(),
        '/newpost_student': (context) => const NewPostStudentScreen(),
        '/search_student': (context) => const SearchStudentScreen(),
        '/messages_student': (context) => const MessagesStudentScreen(),
        '/message_chat_student': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map) {
            final cidRaw = args['conversationId'];
            final cid = cidRaw is int
                ? cidRaw
                : int.tryParse(cidRaw?.toString() ?? '') ?? 0;
            return ChatScreen(
              conversationId: cid,
              title: (args['title'] ?? '').toString(),
              contextLine: (args['contextLine'] ?? '').toString(),
              subtitle: (args['subtitle'] ?? '').toString(),
              canSend: (args['canSend'] == true),
            );
          }

          return const Scaffold(
            body: Center(
              child: Text(
                'Open a conversation from Messages.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        '/profile_student': (context) => const ProfileStudentScreen(),
        '/profile_edit_student': (context) => const ProfileEditStudentScreen(),
        '/add_file_student': (context) => const AddFileScreen(),
        '/camera_student': (context) => const CameraScreen(),
        '/saved_listings_student': (context) => const SavedListingsStudentScreen(),
        '/signup_company': (context) => const SignUpCompanyScreen(),
        '/home_company': (context) => const HomeCompanyScreen(),
        '/search_company': (context) => const SearchCompanyScreen(),
        '/newpost_company': (context) => const NewPostCompanyScreen(),
        '/messages_company': (context) => const MessagesCompanyScreen(),
        '/message_chat_company': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map) {
            final cidRaw = args['conversationId'];
            final cid = cidRaw is int
                ? cidRaw
                : int.tryParse(cidRaw?.toString() ?? '') ?? 0;
            return ChatCompanyScreen(
              conversationId: cid,
              title: (args['title'] ?? '').toString(),
              contextLine: (args['contextLine'] ?? '').toString(),
              subtitle: (args['subtitle'] ?? '').toString(),
              canSend: (args['canSend'] == true),
            );
          }

          return const Scaffold(
            body: Center(
              child: Text(
                'Open a conversation from Messages.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        '/profile_company': (context) => const ProfileCompanyScreen(),
        '/profile_edit_company': (context) => const ProfileEditCompanyScreen(),
        '/add_file_company': (context) => const AddFileCompanyScreen(),
        '/camera_company': (context) => const CameraCompanyScreen(),
        '/saved_listings_company': (context) => const SavedListingsCompanyScreen(),
      },
    );
  }
}

