import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FycoAdminDashboard extends StatefulWidget {
  const FycoAdminDashboard({super.key});

  @override
  State<FycoAdminDashboard> createState() => _FycoAdminDashboardState();
}

class _FycoAdminDashboardState extends State<FycoAdminDashboard> {
  static const ink = Color(0xFF171717);
  static const muted = Color(0xFF77736F);
  static const paper = Color(0xFFF6F3EE);
  static const line = Color(0xFFEAE4DC);
  static const rose = Color(0xFFB77E78);
  static const green = Color(0xFF23856D);
  static const orange = Color(0xFFD28B45);
  static const red = Color(0xFFC65E5E);
  static const purple = Color(0xFF8270B7);

  String _filter = 'all';
  String _search = '';
  String _period = '7d';

  static const statuses = <String, String>{
    'pending_confirmation': 'À confirmer',
    'confirmed': 'Confirmée',
    'preparing': 'En préparation',
    'shipped': 'Expédiée',
    'out_for_delivery': 'En livraison',
    'delivered': 'Livrée & payée',
    'canceled': 'Annulée',
  };

  int _amount(Map<String, dynamic> d) =>
      ((d['totalCodMad'] ?? d['totalAmount'] ?? d['total'] ?? 0) as num).round();

  DateTime? _date(Map<String, dynamic> d) {
    final value = d['createdAt'] ?? d['created_at'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _money(num value) => NumberFormat('#,##0', 'fr_FR').format(value);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(seedColor: rose, brightness: Brightness.light, surface: Colors.white),
        appBarTheme: const AppBarTheme(backgroundColor: paper, foregroundColor: ink, elevation: 0, surfaceTintColor: Colors.transparent),
        textTheme: ThemeData.light().textTheme.apply(bodyColor: ink, displayColor: ink),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: const Color(0xFFF8F6F2),
          hintStyle: const TextStyle(color: muted, fontSize: 13),
          prefixIconColor: muted,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: rose, width: 1.5)),
        ),
      ),
      child: Scaffold(
        backgroundColor: paper,
        appBar: AppBar(
          titleSpacing: 26,
          title: Row(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 19)),
            const SizedBox(width: 11),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('FYCO', style: TextStyle(fontSize: 15, letterSpacing: 3, fontWeight: FontWeight.w900, color: ink)),
              Text('COMMERCE STUDIO', style: TextStyle(fontSize: 8, letterSpacing: 1.8, color: muted, fontWeight: FontWeight.w700)),
            ]),
          ]),
          actions: [
            _topAction(Icons.inventory_2_outlined, 'Produits & stock', () => context.push('/admin/products')),
            const SizedBox(width: 8),
            IconButton(tooltip: 'Déconnexion', onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout_rounded, color: ink)),
            const SizedBox(width: 16),
          ],
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return _errorState(snap.error.toString());
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: rose));
            final docs = snap.data!.docs;
            final now = DateTime.now();
            final days = _period == '30d' ? 30 : 7;
            final periodOrders = docs.where((d) {
              final date = _date(d.data());
              return date != null && date.isAfter(now.subtract(Duration(days: days)));
            }).toList();
            final previousOrders = docs.where((d) {
              final date = _date(d.data());
              return date != null && date.isAfter(now.subtract(Duration(days: days * 2))) && date.isBefore(now.subtract(Duration(days: days)));
            }).toList();
            final delivered = docs.where((d) => d.data()['status'] == 'delivered').toList();
            final revenue = periodOrders.where((d) => d.data()['status'] == 'delivered').fold<int>(0, (sum, d) => sum + _amount(d.data()));
            final previousRevenue = previousOrders.where((d) => d.data()['status'] == 'delivered').fold<int>(0, (sum, d) => sum + _amount(d.data()));
            final pending = docs.where((d) => (d.data()['status'] ?? 'pending_confirmation') == 'pending_confirmation').length;
            final active = docs.where((d) => ['confirmed','preparing','shipped','out_for_delivery'].contains(d.data()['status'])).length;
            final average = delivered.isEmpty ? 0 : delivered.fold<int>(0, (sum,d)=>sum+_amount(d.data())) / delivered.length;
            final conversion = docs.isEmpty ? 0.0 : delivered.length / docs.length * 100;
            final growth = previousRevenue == 0 ? null : ((revenue - previousRevenue) / previousRevenue) * 100;
            final filtered = docs.where((doc) {
              final d = doc.data();
              final status = (d['status'] ?? 'pending_confirmation').toString();
              final customer = (d['customer'] as Map?)?.cast<String,dynamic>() ?? {};
              final q = _search.toLowerCase();
              final matches = q.isEmpty || ['${customer['fullName'] ?? ''}', '${customer['phone'] ?? ''}', '${d['orderRef'] ?? doc.id}'].join(' ').toLowerCase().contains(q);
              return (_filter == 'all' || status == _filter) && matches;
            }).toList();

            final colorCounts = <String,int>{};
            final sizeCounts = <String,int>{};
            for (final doc in docs) {
              for (final raw in (doc.data()['items'] as List?) ?? const []) {
                if (raw is! Map) continue;
                final item = raw.cast<String,dynamic>();
                final color = (item['color'] ?? 'Non précisée').toString();
                final size = (item['size'] ?? '—').toString();
                final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                colorCounts[color] = (colorCounts[color] ?? 0) + qty;
                sizeCounts[size] = (sizeCounts[size] ?? 0) + qty;
              }
            }
            final stockLowStream = FirebaseFirestore.instance.collection('store_products').doc('sculpt-jumpsuit').snapshots();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 44),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('VOTRE BOUTIQUE, EN UN COUP D’ŒIL', style: TextStyle(color: rose, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const SizedBox(height: 8),
                        const Text('Bonjour, FYCO.', style: TextStyle(fontSize: 31, height: 1.05, letterSpacing: -1.2, fontWeight: FontWeight.w900, color: ink)),
                        const SizedBox(height: 7),
                        Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(now), style: const TextStyle(color: muted, fontSize: 13)),
                      ])),
                      SegmentedButton<String>(
                        segments: const [ButtonSegment(value: '7d', label: Text('7 jours')), ButtonSegment(value: '30d', label: Text('30 jours'))],
                        selected: {_period}, onSelectionChanged: (v) => setState(() => _period = v.first),
                        style: SegmentedButton.styleFrom(textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), selectedBackgroundColor: ink, selectedForegroundColor: Colors.white),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    LayoutBuilder(builder: (context, c) {
                      final wide = c.maxWidth > 850;
                      final cards = [
                        _metric('CHIFFRE D’AFFAIRES', '${_money(revenue)} MAD', 'Commandes livrées · période choisie', Icons.payments_outlined, green, growth == null ? null : '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}% vs période précédente'),
                        _metric('NOUVELLES COMMANDES', '${periodOrders.length}', 'Reçues sur la période', Icons.shopping_bag_outlined, purple, null),
                        _metric('À CONFIRMER', '$pending', 'À traiter en priorité', Icons.mark_email_unread_outlined, orange, null),
                        _metric('PANIER MOYEN', '${_money(average)} MAD', 'Sur les commandes livrées', Icons.receipt_long_outlined, rose, null),
                      ];
                      return GridView.count(crossAxisCount: wide ? 4 : c.maxWidth > 540 ? 2 : 1, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: wide ? 1.85 : 2.7, children: cards);
                    }),
                    const SizedBox(height: 18),
                    LayoutBuilder(builder: (context, c) {
                      final wide = c.maxWidth > 850;
                      final chart = _panel(
                        title: 'Performance des ventes',
                        subtitle: 'Revenus encaissés · ${_period == '7d' ? '7 derniers jours' : '30 derniers jours'}',
                        trailing: _tag('${_money(revenue)} MAD', green),
                        child: SizedBox(height: 220, child: _RevenueChart(docs: docs, days: days, dateOf: _date, amountOf: _amount)),
                      );
                      final funnel = _panel(
                        title: 'État des commandes',
                        subtitle: 'Répartition de toutes les commandes',
                        child: SizedBox(height: 220, child: Row(children: [
                          SizedBox(width: 142, child: CustomPaint(painter: _DonutPainter(values: [pending.toDouble(), active.toDouble(), delivered.length.toDouble(), docs.where((d)=>d.data()['status']=='canceled').length.toDouble()], colors: [orange,purple,green,red]), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('${docs.length}', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: ink)), const Text('TOTAL', style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: muted, fontWeight: FontWeight.w800))])))),
                          const SizedBox(width: 18),
                          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            _legend('À confirmer', pending, orange, docs.length),
                            _legend('En traitement', active, purple, docs.length),
                            _legend('Livrées', delivered.length, green, docs.length),
                            _legend('Annulées', docs.where((d)=>d.data()['status']=='canceled').length, red, docs.length),
                          ])),
                        ])),
                      );
                      return wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 6, child: chart), const SizedBox(width: 16), Expanded(flex: 4, child: funnel)]) : Column(children: [chart, const SizedBox(height: 16), funnel]);
                    }),
                    const SizedBox(height: 18),
                    LayoutBuilder(builder: (context, c) {
                      final wide = c.maxWidth > 850;
                      final demand = _panel(title: 'Ce que vos clientes préfèrent', subtitle: 'Variantes commandées · toutes périodes', child: SizedBox(height: 190, child: _DemandBars(colors: colorCounts, sizes: sizeCounts)));
                      final stock = _panel(title: 'Santé du stock', subtitle: 'Sculpt Jumpsuit · stock par variante', child: StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream: stockLowStream, builder: (context, ss) {
                        if (!ss.hasData || !ss.data!.exists) return const Text('Le stock apparaîtra après le premier enregistrement.');
                        final inv = (ss.data!.data()?['inventory'] as Map?)?.cast<String,dynamic>() ?? {};
                        final entries = inv.entries.toList();
                        final total = entries.fold<int>(0,(sum,e)=>sum+((e.value as num?)?.toInt() ?? 0));
                        final low = entries.where((e)=>((e.value as num?)?.toInt() ?? 0) <= 3).length;
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Expanded(child: Text('$total pièces disponibles', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: ink))), _tag(low > 0 ? '$low variantes faibles' : 'Stock OK', low > 0 ? orange : green)]),
                          const SizedBox(height: 15),
                          ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: entries.isEmpty ? 0 : (entries.length-low)/entries.length, minHeight: 9, color: green, backgroundColor: line)),
                          const SizedBox(height: 13),
                          Text(low > 0 ? 'Attention : certaines variantes ont 3 pièces ou moins.' : 'Toutes les variantes suivies sont au-dessus du seuil d’alerte.', style: const TextStyle(color: muted, fontSize: 12, height: 1.4)),
                          const SizedBox(height: 12),
                          Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: ()=>context.push('/admin/products'), icon: const Icon(Icons.tune_rounded, size: 16), label: const Text('Gérer les quantités'))),
                        ]);
                      }));
                      return wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: demand), const SizedBox(width: 16), Expanded(child: stock)]) : Column(children: [demand, const SizedBox(height: 16), stock]);
                    }),
                    const SizedBox(height: 24),
                    Row(children: [
                      const Expanded(child: Text('Commandes récentes', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ink, letterSpacing: -.5))),
                      _tag('${filtered.length} affichées', purple),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextField(onChanged: (v)=>setState(()=>_search=v.trim()), decoration: const InputDecoration(hintText: 'Rechercher nom, téléphone ou référence…', prefixIcon: Icon(Icons.search_rounded)))),
                      const SizedBox(width: 10),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line), borderRadius: BorderRadius.circular(12)), child: DropdownButton<String>(value: _filter, underline: const SizedBox.shrink(), items: [const DropdownMenuItem(value:'all',child:Text('Toutes')), ...statuses.entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value)))], onChanged:(v)=>setState(()=>_filter=v??'all'))),
                    ]),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty) _panel(title: 'Aucun résultat', child: const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Aucune commande ne correspond à votre recherche.', style: TextStyle(color: muted)))))
                    else ...filtered.take(30).map(_orderCard),
                    if (filtered.length > 30) Padding(padding: const EdgeInsets.all(12), child: Center(child: Text('30 commandes affichées sur ${filtered.length}. Affinez votre recherche.', style: const TextStyle(color: muted, fontSize: 12)))),
                    const SizedBox(height: 22),
                    Row(children: [const Icon(Icons.insights_rounded, color: rose, size: 18), const SizedBox(width: 8), Text('Taux de livraison : ${conversion.toStringAsFixed(1)}%  ·  ${active} commandes en cours', style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600))]),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _topAction(IconData icon, String label, VoidCallback action) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: OutlinedButton.icon(onPressed: action, icon: Icon(icon,size:16), label: Text(label), style: OutlinedButton.styleFrom(foregroundColor: ink, side: const BorderSide(color: line), textStyle: const TextStyle(fontSize: 12,fontWeight: FontWeight.w700), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
  );

  Widget _metric(String title, String value, String note, IconData icon, Color color, String? trend) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: line), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 18, offset: Offset(0,5))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [Container(width: 34,height:34,decoration:BoxDecoration(color:color.withOpacity(.12),borderRadius:BorderRadius.circular(11)),child:Icon(icon,color:color,size:18)), const Spacer(), if(trend!=null) _tag(trend, trend.startsWith('-')?red:green)]),
      Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:9,letterSpacing:1.1,fontWeight:FontWeight.w800,color:muted)),const SizedBox(height:4),FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Text(value,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900,color:ink,letterSpacing:-.8))),Text(note,style:const TextStyle(fontSize:10,color:muted))]),
    ]),
  );

  Widget _panel({required String title, String? subtitle, Widget? trailing, required Widget child}) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: line), boxShadow: const [BoxShadow(color: Color(0x07000000),blurRadius:16,offset:Offset(0,4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w900,color:ink)),if(subtitle!=null)Padding(padding:const EdgeInsets.only(top:4),child:Text(subtitle,style:const TextStyle(fontSize:11,color:muted)))])),if(trailing!=null)trailing]),
      const SizedBox(height:17), child,
    ]),
  );

  Widget _tag(String text, Color color) => Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:6),decoration:BoxDecoration(color:color.withOpacity(.11),borderRadius:BorderRadius.circular(20)),child:Text(text,style:TextStyle(color:color,fontSize:10,fontWeight:FontWeight.w800)));

  Widget _legend(String label,int value,Color color,int total)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[Container(width:8,height:8,decoration:BoxDecoration(color:color,shape:BoxShape.circle)),const SizedBox(width:8),Expanded(child:Text(label,style:const TextStyle(fontSize:11,color:muted))),Text('$value',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800,color:ink)),const SizedBox(width:7),Text(total==0?'0%':'${(value/total*100).round()}%',style:const TextStyle(fontSize:10,color:muted))]));

  Widget _orderCard(QueryDocumentSnapshot<Map<String,dynamic>> doc) {
    final d=doc.data(); final customer=(d['customer'] as Map?)?.cast<String,dynamic>()??{};
    final status=(d['status']??'pending_confirmation').toString(); final label=statuses[status]??status;
    final color=status=='delivered'?green:status=='canceled'?red:status=='pending_confirmation'?orange:purple;
    final phone=(customer['phone']??'').toString(); final items=(d['items'] as List?)??const [];
    final date=_date(d);
    return Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:line)),child:LayoutBuilder(builder:(context,c){
      final narrow=c.maxWidth<680;
      final details=Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Text('${d['orderRef']??d['trackingNumber']??doc.id}',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w900,color:ink)),const SizedBox(width:8),_tag(label,color),const Spacer(),if(date!=null)Text(DateFormat('dd/MM · HH:mm').format(date),style:const TextStyle(fontSize:10,color:muted))]),
        const SizedBox(height:8),Text((customer['fullName']??'Client').toString(),style:const TextStyle(fontSize:14,fontWeight:FontWeight.w800,color:ink)),
        Text('${customer['city']??''}  ·  $phone',style:const TextStyle(fontSize:11,color:muted)),
        const SizedBox(height:8),Wrap(spacing:6,runSpacing:6,children:items.whereType<Map>().map((raw){final i=raw.cast<String,dynamic>();return Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(color:paper,borderRadius:BorderRadius.circular(7)),child:Text('${i['productName']??i['title']??'Article'} · ${i['color']??'—'} / ${i['size']??'—'} × ${i['quantity']??1}',style:const TextStyle(fontSize:10,color:muted,fontWeight:FontWeight.w600)));}).toList()),
        const SizedBox(height:7),Text('${_money(_amount(d))} MAD · Paiement à la livraison',style:const TextStyle(fontSize:13,fontWeight:FontWeight.w900,color:ink)),
      ]);
      final actions=Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
        SizedBox(width:narrow?double.infinity:190,child:DropdownButtonFormField<String>(value:statuses.containsKey(status)?status:'pending_confirmation',decoration:const InputDecoration(isDense:true,contentPadding:EdgeInsets.symmetric(horizontal:10,vertical:8)),items:statuses.entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value,style:const TextStyle(fontSize:11)))).toList(),onChanged:(v){if(v!=null)doc.reference.update({'status':v,'lastUpdatedAt':FieldValue.serverTimestamp()});})),
        const SizedBox(height:8),Wrap(spacing:6,children:[
          OutlinedButton.icon(onPressed:phone.isEmpty?null:()=>Clipboard.setData(ClipboardData(text:phone)),icon:const Icon(Icons.copy_rounded,size:14),label:const Text('Téléphone')),
          FilledButton.icon(onPressed:()=>context.push('/track/${doc.id}'),style:FilledButton.styleFrom(backgroundColor:ink,foregroundColor:Colors.white),icon:const Icon(Icons.open_in_new_rounded,size:14),label:const Text('Détails')),
        ]),
      ]);
      return narrow?Column(crossAxisAlignment:CrossAxisAlignment.start,children:[details,const SizedBox(height:14),actions]):Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:details),const SizedBox(width:20),actions]);
    }));
  }

  Widget _errorState(String error)=>Center(child:Container(margin:const EdgeInsets.all(24),padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),child:Text('Impossible de charger les commandes.\n$error',style:const TextStyle(color:red))));
}

class _RevenueChart extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String,dynamic>>> docs;
  final int days;
  final DateTime? Function(Map<String,dynamic>) dateOf;
  final int Function(Map<String,dynamic>) amountOf;
  const _RevenueChart({required this.docs,required this.days,required this.dateOf,required this.amountOf});
  @override Widget build(BuildContext context){
    final now=DateTime.now(); final count=days==7?7:30; final values=List<double>.filled(count,0);
    for(final doc in docs){final d=doc.data();if(d['status']!='delivered')continue;final date=dateOf(d);if(date==null)continue;final age=now.difference(date).inDays;if(age>=0&&age<count)values[count-1-age]+=amountOf(d).toDouble();}
    return CustomPaint(painter:_LinePainter(values),child:Column(children:[Expanded(child:Container()),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(days==7?'J-${count-1}':'30 jours',style:const TextStyle(fontSize:9,color:Color(0xFF99938C))),const Text('Aujourd’hui',style:TextStyle(fontSize:9,color:Color(0xFF99938C)))])]));
  }
}

class _LinePainter extends CustomPainter{
  final List<double> values; _LinePainter(this.values);
  @override void paint(Canvas canvas,Size size){
    const left=4.0,right=4.0,top=10.0,bottom=12.0;final w=size.width-left-right,h=size.height-top-bottom;
    final maxV=values.fold<double>(0,(a,b)=>a>b?a:b);final ceiling=maxV==0?100:maxV*1.2;
    final grid=Paint()..color=const Color(0xFFEFEAE4)..strokeWidth=1;
    for(var i=0;i<4;i++){final y=top+h*i/3;canvas.drawLine(Offset(left,y),Offset(size.width-right,y),grid);}
    final pts=<Offset>[];for(var i=0;i<values.length;i++){final x=left+(values.length==1?0:w*i/(values.length-1));final y=top+h-(values[i]/ceiling*h);pts.add(Offset(x,y));}
    if (pts.isEmpty) return;
    final path = Path()
      ..moveTo(pts.first.dx, top + h)
      ..lineTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.lineTo(pts.last.dx, top + h);
    path.close();
    canvas.drawPath(path,Paint()..shader=const LinearGradient(colors:[Color(0x55B77E78),Color(0x00B77E78)],begin:Alignment.topCenter,end:Alignment.bottomCenter).createShader(Rect.fromLTWH(0,top,size.width,h)));
    final linePath=Path()..moveTo(pts.first.dx,pts.first.dy);for(var i=1;i<pts.length;i++)linePath.lineTo(pts[i].dx,pts[i].dy);
    canvas.drawPath(linePath,Paint()..color=const Color(0xFFB77E78)..style=PaintingStyle.stroke..strokeWidth=2.8..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round);
    for(final p in pts){canvas.drawCircle(p,3.3,Paint()..color=Colors.white);canvas.drawCircle(p,2,Paint()..color=const Color(0xFFB77E78));}
  }
  @override bool shouldRepaint(covariant _LinePainter old)=>old.values!=values;
}

class _DonutPainter extends CustomPainter{
  final List<double> values;final List<Color> colors;_DonutPainter({required this.values,required this.colors});
  @override void paint(Canvas canvas,Size size){final rect=Rect.fromLTWH(8,8,size.width-16,size.height-16);final total=values.fold<double>(0,(a,b)=>a+b);final base=Paint()..color=const Color(0xFFF0ECE7)..style=PaintingStyle.stroke..strokeWidth=15;canvas.drawArc(rect,0,math.pi*2,false,base);if(total==0)return;var start=-math.pi/2;for(var i=0;i<values.length;i++){if(values[i]<=0)continue;final sweep=values[i]/total*math.pi*2;canvas.drawArc(rect,start,sweep-0.035,false,Paint()..color=colors[i]..style=PaintingStyle.stroke..strokeWidth=15..strokeCap=StrokeCap.round);start+=sweep;}}
  @override bool shouldRepaint(covariant _DonutPainter old)=>old.values!=values;
}

class _DemandBars extends StatelessWidget{
  final Map<String,int> colors;final Map<String,int> sizes;const _DemandBars({required this.colors,required this.sizes});
  @override Widget build(BuildContext context){
    const palette=[Color(0xFFB77E78),Color(0xFF6F8299),Color(0xFFB99561),Color(0xFF8B7AB5),Color(0xFF6F9C8C)];
    final entries=colors.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));final sizeEntries=sizes.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    if(entries.isEmpty&&sizeEntries.isEmpty)return const Center(child:Text('Les préférences apparaîtront avec les premières commandes.',style:TextStyle(fontSize:11,color:Color(0xFF77736F))));
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('COULEURS',style:TextStyle(fontSize:9,letterSpacing:1.4,fontWeight:FontWeight.w900,color:Color(0xFF77736F))),
      const SizedBox(height:8),
      for(var i=0;i<math.min(3,entries.length);i++)_bar(entries[i].key,entries[i].value,entries.first.value,_swatch(entries[i].key,palette[i%palette.length])),
      const SizedBox(height:13),
      const Text('TAILLES',style:TextStyle(fontSize:9,letterSpacing:1.4,fontWeight:FontWeight.w900,color:Color(0xFF77736F))),
      const SizedBox(height:8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in sizeEntries.take(5))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${entry.key}  ·  ${entry.value}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171717),
                ),
              ),
            ),
        ],
      ),
    ]);
  }
  Color _swatch(String name, Color fallback) {
    final n=name.toLowerCase();
    if(n.contains('white')||n.contains('blanc')||n.contains('milk')) return const Color(0xFFE8E2D8);
    if(n.contains('choc')||n.contains('brown')||n.contains('brun')) return const Color(0xFF795548);
    if(n.contains('pink')||n.contains('rose')||n.contains('éclat')) return const Color(0xFFE69AAE);
    if(n.contains('black')||n.contains('noir')) return const Color(0xFF242424);
    if(n.contains('blue')||n.contains('bleu')) return const Color(0xFF7799C2);
    return fallback;
  }
  Widget _bar(String label,int value,int max,Color color)=>Padding(padding:const EdgeInsets.only(bottom:7),child:Row(children:[Container(width:13,height:13,decoration:BoxDecoration(color:color,shape:BoxShape.circle,border:Border.all(color:const Color(0x22000000)))),const SizedBox(width:8),SizedBox(width:82,child:Text(label,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,color:Color(0xFF171717)))),Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(10),child:LinearProgressIndicator(value:max==0?0:value/max,minHeight:8,color:color,backgroundColor:const Color(0xFFF0ECE7)))),const SizedBox(width:8),Text('$value',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w800,color:Color(0xFF171717)))]));
}
