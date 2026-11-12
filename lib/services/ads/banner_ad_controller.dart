import 'ad_configuration.dart';
import 'ad_mob_service.dart';
import 'inline_ad_controller.dart';

class BannerAdController extends InlineAdController {
  BannerAdController(AdMobService service) : super(service, format: AdFormat.banner);
}
