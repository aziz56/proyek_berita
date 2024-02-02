import 'dart:convert';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class NewsDataSource {
  final String apiKey = '4b397c0b925c48649a61b00c6ab69622';
  final String baseUrl = 'https://newsapi.org/v2';

  Future<List<Article>> getArticles(String keyword) async {
    final url = '$baseUrl/everything?q=$keyword&apiKey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final articlesData = jsonData['articles'] as List<dynamic>;

      final articles = articlesData.map((data) => Article.fromJson(data)).toList();
      return articles;
    } else {
      throw Exception('Failed to load articles');
    }
  }
}

class Article {
  final String title;
  final String description;
  final String url;

  Article({required this.title, required this.description, required this.url});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'],
      description: json['description'],
      url: json['url'],
    );
  }
}

class NewsRepository {
  var _dataSource = NewsDataSource();
  Future<List<Article>> getArticles(String keyword) async {
    try {
      return await _dataSource.getArticles(keyword);
    } catch (e) {
      throw Exception('Failed to load articles: $e');
    }
  }
}

class GetArticlesUseCase {
  var _repository = NewsRepository();

  Future<List<Article>> execute(String keyword) async {
    try {
      return await _repository.getArticles(keyword);
    } catch (e) {
      throw Exception('Failed to get articles: $e');
    }
  }
}

class ClassNewsPage extends StatefulWidget {
  @override
  _ClassNewsPageState createState() => _ClassNewsPageState();
}

class _ClassNewsPageState extends State<ClassNewsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _useCase = GetArticlesUseCase();

  void _searchArticles(String keyword) async {
    final articles = await _useCase.execute(keyword);
    print(articles);
  }
  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Home'),
            Tab(text: 'Favorite'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          WebView(
            initialUrl: 
            javascriptMode: JavascriptMode.unrestricted,
          ),
          WebView(

          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Perform action when the button is pressed
        },
        child: Icon(Icons.add),
      ),
    );
  }
}








// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class MyTabBarWidget extends StatefulWidget {
//   @override
//   _MyTabBarWidgetState createState() => _MyTabBarWidgetState();
// }

// class _MyTabBarWidgetState extends State<MyTabBarWidget> with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('My TabBar'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: [
//             Tab(text: 'Home'),
//             Tab(text: 'Favorite'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           WebView(
//             initialUrl: 'https://www.example.com/home',
//             javascriptMode: JavascriptMode.unrestricted,
//           ),
//           WebView(
//             initialUrl: 'https://www.example.com/favorite',
//             javascriptMode: JavascriptMode.unrestricted,
//           ),
//         ],
//       ),
//     );
//   }
// }
