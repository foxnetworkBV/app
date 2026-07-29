import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final SessionService session;
  const LoginScreen({super.key, required this.session});
  @override State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  bool loading=false, _cancelPolling=false; String? error;
  Future<void> loginWithPaymenter() async { _cancelPolling=true; setState((){loading=true;error=null;}); try { final auth=await widget.session.beginPaymenterLogin(); final opened=await launchUrl(auth.authorizationUrl,mode:LaunchMode.externalApplication); if(!opened) throw Exception('Could not open the FoxNetwork login page.'); _cancelPolling=false; await _waitForLogin(auth.state); } catch(e){if(mounted)setState((){loading=false;error=e.toString().replaceFirst('Exception: ','');});}}
  Future<void> _waitForLogin(String state) async { for(var i=0;i<100;i++){if(_cancelPolling||!mounted)return;if(await widget.session.pollPaymenterLogin(state)){if(mounted)setState((){loading=false;error=null;});return;}await Future<void>.delayed(const Duration(seconds:3));}throw Exception('The login request timed out. Please try again.');}
  @override void dispose(){_cancelPolling=true;super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(body:Stack(children:[
    Positioned.fill(child:Container(color:FoxColors.page)),
    Positioned(top:-110,right:-100,child:Container(width:300,height:300,decoration:BoxDecoration(color:FoxColors.orange.withValues(alpha:.09),shape:BoxShape.circle))),
    Positioned(bottom:-150,left:-120,child:Container(width:360,height:360,decoration:BoxDecoration(color:FoxColors.navy.withValues(alpha:.05),shape:BoxShape.circle))),
    SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:430),child:Column(children:[
      Image.asset('assets/foxnetwork_logo.png',width:118,height:118),
      const SizedBox(height:20),
      const Text('Welcome to FoxNetwork',textAlign:TextAlign.center,style:TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:FoxColors.navy,letterSpacing:-.7)),
      const SizedBox(height:9),
      const Text('Manage your hosting, invoices and support from one secure app.',textAlign:TextAlign.center,style:TextStyle(fontSize:15,height:1.5,color:FoxColors.muted)),
      const SizedBox(height:30),
      Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:FoxColors.border),boxShadow:const [BoxShadow(color:Color(0x120F1A30),blurRadius:30,offset:Offset(0,14))]),child:Column(children:[
        Row(children:[Container(width:44,height:44,decoration:BoxDecoration(color:FoxColors.orange.withValues(alpha:.1),borderRadius:BorderRadius.circular(14)),child:const Icon(Icons.shield_outlined,color:FoxColors.orange)),const SizedBox(width:13),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Secure customer login',style:TextStyle(fontWeight:FontWeight.w800,color:FoxColors.navy)),SizedBox(height:2),Text('Powered by your FoxNetwork account',style:TextStyle(fontSize:12,color:FoxColors.muted))]))]),
        if(error!=null)...[const SizedBox(height:18),Container(width:double.infinity,padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:Colors.red.shade50,borderRadius:BorderRadius.circular(13)),child:Text(error!,style:TextStyle(color:Colors.red.shade800),textAlign:TextAlign.center))],
        const SizedBox(height:22),
        SizedBox(width:double.infinity,child:DecoratedBox(decoration:BoxDecoration(gradient:FoxColors.primaryGradient,borderRadius:BorderRadius.circular(15),boxShadow:const [BoxShadow(color:Color(0x40EA5411),blurRadius:18,offset:Offset(0,8))]),child:FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:Colors.transparent,shadowColor:Colors.transparent),onPressed:loading?null:loginWithPaymenter,icon:loading?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.login_rounded),label:Padding(padding:const EdgeInsets.symmetric(vertical:2),child:Text(loading?'Waiting for authorization…':'Continue to FoxNetwork'))))),
      ])),
      const SizedBox(height:18),const Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.lock_outline_rounded,size:15,color:FoxColors.muted),SizedBox(width:6),Text('Your password is never stored in this app',style:TextStyle(fontSize:12,color:FoxColors.muted))]),
    ]))))),
  ]));
}
