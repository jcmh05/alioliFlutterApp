import 'package:alioli/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'screens.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

const _iconPages = <String, IconData>{
  'home': Icons.home,
  'discover': Icons.map,
  'search': Icons.search,
  'myrecipes': Icons.menu_book_outlined,
  'account': Icons.account_circle,
};

class _MainScreenState extends State<MainScreen> {

  static var pages = <Widget>[
    HomeScreen(),
    DiscoverScreen(),
    SearchScreen(),
    MyRecipesScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Nº de pestañas de la barra
      initialIndex: LocalStorage().getInitialPage(),
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                physics: NeverScrollableScrollPhysics(),
                children: pages,
              ),
            ),
          ],
        ),
        bottomNavigationBar: ConvexAppBar(
          backgroundColor: Color(0xFF11AF41),
          style: TabStyle.reactCircle,
          items: <TabItem>[
            for (final entry in _iconPages.entries)
              TabItem(icon: entry.value),
          ],
          //onTap: (int i) => print('Índice =$i'),
        ),
      ),
    );

  }

}
