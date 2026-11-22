# Gujarat Vehicle Market — આગળ વધારેલો Flutter પ્રોજેક્ટ

## ઉમેરાયેલ સુવિધાઓ
- ફોન નંબરથી Firebase OTP login
- અલગ Buy Vehicle સ્ક્રીન: કાર, બાઈક, ટ્રક અને ટ્રેક્ટર
- Sell Vehicle ફોર્મ: કેટેગરી, મોડેલ, કિંમત, શહેર/ગામ અને વર્ણન
- Firestore માં જાહેરાત સેવ કરવી અને કેટેગરી પ્રમાણે જોવી
- જાહેરાત સાથે વધુમાં વધુ 5 ફોટા પસંદ કરીને Firebase Storage માં અપલોડ કરવા
- ખરીદનારની યાદીમાં જાહેરાતનો પહેલો ફોટો બતાવવો
- જાહેરાતના વેચનાર સાથે ખાનગી in-app chat: મેસેજ real-time માં Firestore પર દેખાય છે
- Chat room માં માત્ર ખરીદનાર અને તે જાહેરાતનો વેચનાર જ ભાગ લઈ શકે તે માટે `firestore.rules` માં access rules
- કેટેગરીની અંદર નામ, મોડેલ, શહેર/ગામ અને વર્ણન પ્રમાણે વાહન શોધવું
- ઓછામાં ઓછી અને વધુમાં વધુ કિંમત પ્રમાણે ફિલ્ટર કરવું
- નવી જાહેરાત પહેલા, ઓછી કિંમત પહેલા અથવા વધુ કિંમત પહેલા પ્રમાણે ગોઠવવું
- જાહેરાત બનાવનાર જ પોતાની જાહેરાત ડિલીટ કરી શકે તે માટે UI ચેક અને `firestore.rules`

## ચલાવવા માટે
1. Flutter SDK ઇન્સ્ટોલ કરો અને project folder ખોલો.
2. Firebase project બનાવો અને Authentication માં Phone sign-in ચાલુ કરો.
3. Firestore Database બનાવો.
4. Firebase Console માં Storage ચાલુ કરો અને `storage.rules` ના નિયમો Firebase Storage Rules માં publish કરો.
5. FlutterFire CLI ચલાવી `flutterfire configure` કરો. `main.dart` માં generated `firebase_options.dart` import કરીને `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` વાપરો.
6. Firebase Console ના Firestore Rules વિભાગમાં `firestore.rules` ની rules publish કરો.
7. `flutter pub get` અને `flutter run` ચલાવો.

## હજી બાકી / નોંધ
- Edit listing, admin moderation અને Play Store publishing હજી બાકી છે.
- Chat ચલાવવા માટે Firebase Console માં `firestore.rules` ના નવા નિયમો publish કરવાના રહેશે.
- Firebase project configuration વગર OTP અને database ચલાવી શકાશે નહીં.
- Security માટે Firestore rules ફરજિયાત publish કરો; ફક્ત એપના UI પર આધાર ન રાખો.

## Chat ચાલુ કરવા માટે
1. Firebase Console માં તમારો project ખોલો.
2. Firestore Database → Rules ખોલો.
3. ZIP માંનો `firestore.rules` ખોલીને તેનો આખો કોડ Rules editor માં મૂકો.
4. Publish દબાવો.
5. એપમાં લૉગિન કરેલા ખરીદનાર વાહનની જાહેરાતમાં Chat બટન દબાવી વેચનારને મેસેજ કરી શકે છે.

નોંધ: આ ZIP source code છે; APK નથી. Firebase rules publish અને Android build કર્યા પછી જ ફોનમાં install કરી શકાશે.

## ભાષા બદલવાની સુવિધા
- એપના ઉપરના Language (🌐) બટનથી ગુજરાતી, हिन्दी અને English પસંદ કરી શકાય છે.
- ભાષા બદલવાથી એપના મુખ્ય લોગિન, ખરીદી, શોધ, કિંમત ફિલ્ટર, વેચાણ અને સંદેશાના લખાણો બદલાય છે.
- વાહન કેટેગરીના Firestore મૂલ્યો ગુજરાતી જ રાખવામાં આવ્યા છે જેથી જૂની જાહેરાતો સાથે સુસંગતતા રહે.

## ખરીદનાર-વેચનાર સંપર્ક
- વેચનાર જાહેરાત ઉમેરતી વખતે વૈકલ્પિક 10 અંકનો સંપર્ક નંબર આપી શકે છે.
- નંબર આપતા પહેલાં વેચનારની સ્પષ્ટ પસંદગી જરૂરી છે; ફોર્મમાં જણાવવામાં આવે છે કે આ નંબર ખરીદદારોને દેખાશે.
- ખરીદનાર જાહેરાત પર સંપર્ક આઇકનથી ફોન કૉલ અથવા WhatsApp ખોલી શકે છે.
- નંબર ન આપ્યો હોય તો સંપર્ક બટન દેખાતું નથી.
- આ સુવિધા માટે `url_launcher` dependency ઉમેરવામાં આવી છે.
