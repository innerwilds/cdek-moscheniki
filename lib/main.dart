import 'package:cdek_reviews/_reviews.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:web/web.dart' as web;

void main() {
  runApp(Provider(
    data: const ReviewsRepo(),
    child: const App(),
  ));
}

const CDEKProbablyAdminka = "https://panel.cdek.shopping/";

final class CDEKEmployeeMode {
  final bool enabled;
  const CDEKEmployeeMode({required this.enabled});
}

final themeData = ThemeData.from(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.purpleAccent,
  ),
);
const mainNavigationItems = [
  (label: 'Отзывы', builder: Reviews.builder),
  (label: 'О сайте', builder: About.builder),
];

/// Currently all reviews will be stored under /reviews/verified for verified
/// and /reviews/unverified for unverified.
///
/// So i need to recompile this?
class ReviewsRepo {
  const ReviewsRepo();

  int availableCount() {
    return REVIEWS.length;
  }

  Stream<Review> view(int from, int to) {
    return Stream.fromIterable(REVIEWS.skip(from).take(to - from));
  }

  Future<Review> getByIndex(int idx) async {
    return REVIEWS[idx];
  }

  Future<Review> get(String id) async {
    return REVIEWS.firstWhere((item) => id == item.id);
  }
}

class App extends StatefulWidget {
  const App({
    super.key,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: themeData,
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentPage = 0;
  bool isCdekEmployeeMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        centerTitle: true,
        toolbarHeight: 132,
        title: Padding(
          padding: EdgeInsets.all(16.0),
          child: Image.asset('assets/logo_reviews.png',
            height: 100,
            filterQuality: FilterQuality.low,
            isAntiAlias: true,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 800
            ),
            child: Column(
              children: [
                Gap.y(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final (index, item) in mainNavigationItems.indexed)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                currentPage = index;
                              });
                            },
                            child: Text(item.label),
                          ),
                      ],
                    ),
                    Card.filled(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text('Режим сотрудника CDEK'),
                            Switch(
                              value: isCdekEmployeeMode,
                              onChanged: (v) {
                                setState(() {
                                  isCdekEmployeeMode = v;
                                });
                              },
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                Gap.y(20),
                Provider<CDEKEmployeeMode>(
                  data: CDEKEmployeeMode(enabled: isCdekEmployeeMode),
                  child: mainNavigationItems[currentPage].builder(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Reviews extends StatefulWidget {
  const Reviews({super.key});

  static Widget builder(BuildContext context) {
    return const Reviews();
  }

  @override
  State<Reviews> createState() => _ReviewsState();
}

class _ReviewsState extends State<Reviews> {
  PagingController<int, Review> controller = PagingController(firstPageKey: 0);

  Future<void> fetch(int page) async {
    final repo = context.read<ReviewsRepo>()!;
    final newItems = await repo.view(page, page + 20).toList();
    final isLastPage = newItems.length < 20;
    if (isLastPage) {
      controller.appendLastPage(newItems);
    } else {
      final nextPageKey = page + newItems.length;
      controller.appendPage(newItems, nextPageKey);
    }
  }

  @override
  void initState() {
    super.initState();
    controller.addPageRequestListener((pageKey) {
      fetch(pageKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}
class About extends StatelessWidget {
  const About({super.key});

  static Widget builder(BuildContext context) {
    return const About();
  }

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining();
  }
}

class ReviewView extends StatelessWidget {
  const ReviewView({
    super.key,
    required this.review,
  });

  final Review review;

  @override
  Widget build(BuildContext context) {
    final isCDEKEmployeeModeEnabled = context.watch<CDEKEmployeeMode>()!.enabled;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundImage: review.author.avatar != null
                      ? MemoryImage(
                    review.author.avatar!,
                  )
                      : null,
                ),
                Gap.x(20),
                Text('${review.author.lastName} ${review.author.firstName}'),
              ],
            ),
            Gap.y(20),

            if (isCDEKEmployeeModeEnabled)
              switch (review.fraudType) {
                FraudType.withheldRefund => Center(
                  child: FilledButton(
                    onPressed: () {
                      launchUrlString(CDEKProbablyAdminka);
                    },
                    child: Text(
                        'Вернуть деньги'
                    ),
                  ),
                ),
                FraudType.ohMyGodShitfulService => Center(
                  child: Text('Этот человек считает ваш сервис убогим д***мом'),
                ),
              }
            else
              Text(review.text)
          ],
        ),
      ),
    );
  }
}


class Gap extends StatelessWidget {
  const Gap.x(this._x, {super.key}) : _y = 0.0;
  const Gap.y(this._y, {super.key}) : _x = 0.0;

  final double _x;
  final double _y;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: _y,
        left: _x,
      ),
    );
  }
}

class Provider<T extends Object> extends InheritedWidget {
  const Provider({
    super.key,
    required this.data,
    required super.child,
  });

  final T data;

  @override
  bool updateShouldNotify(Provider oldWidget) {
    return oldWidget.data != data;
  }
}

extension OnBC on BuildContext {
  T? read<T extends Object>() {
    return findAncestorWidgetOfExactType<Provider<T>>()?.data;
  }

  T? watch<T extends Object>() {
    return dependOnInheritedWidgetOfExactType<Provider<T>>()?.data;
  }
}
