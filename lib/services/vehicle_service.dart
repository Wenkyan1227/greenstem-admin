import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle.dart';

class VehicleService {
  final CollectionReference _vehicleBrandsCollection = FirebaseFirestore
      .instance
      .collection('vehicle_brands');

  // Get all vehicle brands
  Stream<List<VehicleBrand>> getVehicleBrands() {
    return _vehicleBrandsCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => VehicleBrand.fromFirestore(doc))
          .toList();
    });
  }

  // Get vehicle brand by ID
  Future<VehicleBrand?> getVehicleBrandById(String brandId) async {
    DocumentSnapshot doc = await _vehicleBrandsCollection.doc(brandId).get();
    if (doc.exists) {
      return VehicleBrand.fromFirestore(doc);
    }
    return null;
  }

  // Create a new vehicle brand
  Future<void> createVehicleBrand(VehicleBrand brand) async {
    await _vehicleBrandsCollection.add(brand.toFirestore());
  }

  // Update a vehicle brand
  Future<void> updateVehicleBrand(VehicleBrand brand) async {
    await _vehicleBrandsCollection.doc(brand.id).update(brand.toFirestore());
  }

  // Delete a vehicle brand
  Future<void> deleteVehicleBrand(String brandId) async {
    await _vehicleBrandsCollection.doc(brandId).delete();
  }

  // List<Map<String, dynamic>> vehicleBrandsData = [
  //   // Toyota Brand
  //   {
  //     'name': 'Toyota',
  //     'logoUrl':
  //         'https://th.bing.com/th/id/OIP.KK-fnn2aJDElee63Y2cBBQHaHZ?w=165&h=180&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
  //     'models': [
  //       {
  //         'id': 'toyota_camry',
  //         'name': 'Camry',
  //         'imageUrl':
  //             'https://www.toyota.com.my/content/dam/malaysia/models/camry-ice/explore-thumbnail/camry-ice-navi.png',
  //       },
  //       {
  //         'id': 'toyota_corolla',
  //         'name': 'Corolla',
  //         'imageUrl':
  //             'https://www.toyota.com.my/content/dam/malaysia/models/corolla/explore-thumbnails/corolla-gray-thumbnail.png',
  //       },
  //       {
  //         'id': 'toyota_gr86',
  //         'name': 'GR86',
  //         'imageUrl':
  //             'https://www.toyota.com.my/content/dam/malaysia/models/gr-86/explore-thumbnails/toyota-gr-86-navi.png',
  //       },
  //       {
  //         'id': 'toyota_yaris',
  //         'name': 'Yaris',
  //         'imageUrl':
  //             'https://www.toyota.com.my/content/dam/malaysia/models/yaris/explore-thumbnails/explore-thumbnail-red-black-yaris.png',
  //       },
  //       {
  //         'id': 'toyota_harrier',
  //         'name': 'Harrier',
  //         'imageUrl':
  //             'https://www.toyota.com.my/content/dam/malaysia/models/harrier/explore-thumbnails/explore-thumbnail-219-precious-black-harrier.png',
  //       },
  //       {
  //         'id': 'toyota_fortuner',
  //         'name': 'Fortuner',
  //         'imageUrl':
  //             'https://www.toyota.com.my/content/dam/malaysia/models/fortuner/explore-thumbnail/explore-thumbnail-super-white-ii-black-roof-fortuner.png',
  //       },
  //     ],
  //   },
  //   // Honda Brand
  //   {
  //     'name': 'Honda',
  //     'logoUrl':
  //         'https://th.bing.com/th/id/OIP.q7iUvhzbZXMnD0qDnXO_egHaE_?w=261&h=180&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
  //     'models': [
  //       {
  //         'id': 'honda_city',
  //         'name': 'City',
  //         'imageUrl':
  //             'https://evault.honda.com.my/pixelvault/2025-08/694d09410cd79063f667444f3b6f01c54d04ae7026293.png',
  //       },
  //       {
  //         'id': 'honda_civic',
  //         'name': 'Civic',
  //         'imageUrl':
  //             'https://evault.honda.com.my/pixelvault/2025-08/255f19fb136f65c512a38bbd465d83e62703886313007.png',
  //       },
  //       {
  //         'id': 'honda_accord',
  //         'name': 'Accord',
  //         'imageUrl':
  //             'https://honda-kl.com/images/car-models/accord/colors-2020/honda-accord-white-orchid-pearl.png',
  //       },
  //       {
  //         'id': 'honda_crv',
  //         'name': 'CR-V',
  //         'imageUrl':
  //             'https://evault.honda.com.my/pixelvault/2025-08/cd8fc9622c7a5a06efa9871c1a13919d503170e968944.png',
  //       },
  //       {
  //         'id': 'honda_hrv',
  //         'name': 'HR-V',
  //         'imageUrl':
  //             'https://evault.honda.com.my/pixelvault/2025-07/a4829ecb0083b9766a72749cab4ff1c1ade4e0e846153.png',
  //       },
  //       {
  //         'id': 'honda_wrv',
  //         'name': 'WR-V',
  //         'imageUrl':
  //             'https://evault.honda.com.my/pixelvault/2025-08/77b812bca1475f7248a453ccaa053741cc6fdb3197184.png',
  //       },
  //     ],
  //   },
  //   // Proton Brand
  //   {
  //     'name': 'Proton',
  //     'logoUrl':
  //         'https://th.bing.com/th/id/OIP.b6TEtJZy6bfF8ugJHPMETgHaEK?w=277&h=180&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
  //     'models': [
  //       {
  //         'id': 'proton_x50',
  //         'name': 'X50',
  //         'imageUrl':
  //             'https://www.proton.com/-/media/project/proton-group/proton/SkinChange/vector/model-white-text-allnewX50',
  //       },
  //       {
  //         'id': 'proton_x70',
  //         'name': 'X70',
  //         'imageUrl':
  //             'https://www.proton.com/-/media/project/proton-group/proton/SkinChange/vector/model-white-text-X70',
  //       },
  //       {
  //         'id': 'proton_x90',
  //         'name': 'X90',
  //         'imageUrl':
  //             'https://www.proton.com/-/media/project/Proton%20Group/Proton/Images/Cars/X90/X90-thumb-nav',
  //       },
  //       {
  //         'id': 'proton_s70',
  //         'name': 'S70',
  //         'imageUrl':
  //             'https://www.proton.com/-/media/project/proton-group/proton/images/cars/s70/model-white-text-s70.ashx?h=648&w=100%25&la=en&hash=C52DAC078AFB5B8622C24331B4FD702D5E9334E5',
  //       },
  //       {
  //         'id': 'proton_saga',
  //         'name': 'Saga',
  //         'imageUrl':
  //             'https://www.proton.com/-/media/project/proton-group/proton/SkinChange/vector/model-white-text-SAGA',
  //       },
  //       {
  //         'id': 'proton_persona',
  //         'name': 'Persona',
  //         'imageUrl':
  //             'https://www.proton.com/-/media/project/proton-group/proton/SkinChange/vector/model-white-text-PERSONA?w=100%25&hash=D82EABD45FC33CE23C4D18B7A272BD8CF3A8996C',
  //       },
  //     ],
  //   },
  //   // Perodua Brand
  //   {
  //     'name': 'Perodua',
  //     'logoUrl':
  //         'https://tse2.mm.bing.net/th/id/OIP._JLX_NBRZlu4gPoTzvjqvwHaFK?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
  //     'models': [
  //       {
  //         'id': 'perodua_axia',
  //         'name': 'Axia',
  //         'imageUrl':
  //             'https://www.perodua.com.my/includes/imageresize.php?width=400&quality=75&image=/assets/images/landing-page/cars/with-emblem/axia.webp',
  //       },
  //       {
  //         'id': 'perodua_myvi',
  //         'name': 'Myvi',
  //         'imageUrl':
  //             'https://www.perodua.com.my/includes/imageresize.php?width=400&quality=75&image=/assets/images/landing-page/cars/with-emblem/myvi.webp',
  //       },
  //       {
  //         'id': 'perodua_bezza',
  //         'name': 'Bezza',
  //         'imageUrl':
  //             'https://www.perodua.com.my/includes/imageresize.php?width=400&quality=75&image=/assets/images/landing-page/cars/with-emblem/bezza.webp',
  //       },
  //       {
  //         'id': 'perodua_aruz',
  //         'name': 'Aruz',
  //         'imageUrl':
  //             'https://www.perodua.com.my/includes/imageresize.php?width=400&quality=75&image=/assets/images/landing-page/cars/with-emblem/aruz.webp',
  //       },
  //       {
  //         'id': 'perodua_ativa',
  //         'name': 'Ativa',
  //         'imageUrl':
  //             'https://www.perodua.com.my/includes/imageresize.php?width=400&quality=75&image=/assets/images/landing-page/cars/with-emblem/ativa.webp',
  //       },
  //       {
  //         'id': 'perodua_alza',
  //         'name': 'Alza',
  //         'imageUrl':
  //             'https://www.perodua.com.my/includes/imageresize.php?width=400&quality=75&image=/assets/images/landing-page/cars/with-emblem/alza.webp',
  //       },
  //     ],
  //   },
  //   // BMW Brand
  //   {
  //     'name': 'BMW',
  //     'logoUrl':
  //         'https://th.bing.com/th/id/OIP.kXCVab42euiDk2mReUSSoQHaHa?w=160&h=180&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
  //     'models': [
  //       {
  //         'id': 'bmw_x5',
  //         'name': 'X5',
  //         'imageUrl':
  //             'https://prod.cosy.bmw.cloud/bmwweb/cosySec?COSY-EU-100-73317K9wt0u4fXBI1TL3hL4CRf1xEaxjFGe89RbfKYmUrOpQhRVAfyq3VraezL14UDyeONayV%25OkaotUZ7WcMtECUkUSb7slGAGhRCrXpFkPslZQ6KAOPXRaYWFLVQ5nmPKIFagOybWBanvIT91heO2B3iEXMIjedwsj3BDMztruNeqhk7ZI5MLoACRKwhJHFlMEfou%25KXh7FHSfWQoCu%25V1PaHMGfNEbn%25hV10s9OfeFE4riI1DoscZwBEpjrxRtesrBZ857Mr2IRUgChZ885GvloRV5gp2XHB1Dv6jQ%25eTQ2YDafM3Vjmqn1hdmDyLOEo2tqTJIsNxyL3uBr0ABJdSeZ4FjuzVMRcKlSkNh5xQiVA0og8anNF4HvU8f0Kc%252G7Q4WxfjpTCcP81D7vkxbUEqC2889GsLleUUi5CoMAShdqfKLqNF1yQmSDyPMIooubQYgMdvRUQ8J2jD5lk1tcDVXOyzoVBDFhfGHNekxo7016MLWo0CqXhFUcm7RagdQPBaCnTNk9mlDWLfV91KVZ0pEuTQLfrphUrOTawFVAf4bLswTZ2M6djrtCl',
  //       },
  //       {
  //         'id': 'bmw_ix',
  //         'name': 'IX',
  //         'imageUrl':
  //             'https://prod.cosy.bmw.cloud/bmwweb/cosySec?COSY-EU-100-7331RYechZ7dyKBJHS9gwyljT5lkQM37fNw9zKPbuDShtlo9P2YI6NLJujnWZXGucOMzK1coub0TmvayRCzjlCO2kwxEa6sfNws53ZG19mrOpg3E47EvkeQajnWjHAanDyeU5pDHtQYgMJNRUQAP13%25P6RGNDIjAOihIQBzcKt3aJDW2aK0De2VrtGZH9urxRteIgOZ857Mu1vRUgChSE35GvloVGCgp2XHN1Gv6jQ%2505c2YDaf4eQjmqn1cMSDyLOEjVnqTJIsDvyL3uBrq2wJdSeZLdruzVMRJv9SkNh5uWCVA0ogSEoNF4HvVfX0Kc%252NF84Wxfj0UucP81D5JGxbUEqYuF89GsLm70UiprJyCeGw6ZuTy5ptYRS3OM67m5VdKIYCygNOu9mlTv0QCUyX324alzTQdjcnXf3aJwEiyGwIvRjjmBYXGuSDOPLFtnZ8XgY1nTNIowJ4HO3zk',
  //       },
  //       {
  //         'id': 'bmw_5_series_sedan',
  //         'name': '5 Series Sedan',
  //         'imageUrl':
  //             'https://prod.cosy.bmw.cloud/bmwweb/cosySec?COSY-EU-100-73317K9wt0u4fX7JAcL3hL4CRf1xEaxTVGe89RbfKYmUrOpQhRVAfyq3VraezL14UDyeONayV%25OkaotUZ7WcMtECUkUSb7slGAGwdCrXpFkzalZQ6KAwXXRaYWFLVQ5nmPKR7agOybWBKnvIT9PeTO2B3iEoMIjedwsbLBDMztraoeqhk7ZqzMLoACRBmhJHFl5gLou%25KXh7NHSfWQoeU%25V1PaHMSfNEbn%25Nf10s9OfeFE4riI1usscZwBEqHrxRtesLcZ857MrYqRUgChZjB5GvloRD5gp2XH5GGv6jQ%25g0v2YDafMS6jmqn1hrJDyLOEozxqTJIsHkKL3uBr%25DpJdSeZ4CmuzVMRcKMSkNh5xWqVA0og8PQNF4HvUnt0Kc%252GOI4WxfjpGEcP81D63lxbUEqYd189GsLljFUiprJXKKGw6ZuQhpptYRSaJH67m5Vm8YYCygNycBmlTv0TWiyX3243B0TQdjcdX13azDxzQndnkq8IaYzOALUBnKkIFJGeOrABKup08jFe0H2gXmv7GqapGTQLi19mUiOgZ22YI1b4g7cNF1A6x8U0%25lLhzUyfriC2yRUQvqKjT5lk2ockYgpn23HGfvQFz9oNE471OREHswTlB9%25UnpqyBLayV3WJYw1pqSWvFSrwEMQyXqdIpuMwVxgP78ShH%25',
  //       },
  //       {
  //         'id': 'bmw_x3',
  //         'name': 'X3',
  //         'imageUrl':
  //             'https://prod.cosy.bmw.cloud/bmwweb/cosySec?COSY-EU-100-7331RYechZ7dyKBJHS9gwyljT5lkQM37fNw9zKPbuDShtDo4i2YI6NLJujnWZXGucOMzK1coub0TmvayRCzjlCO2kwxEa6sfNws53ZG19mrOpeTE47EvkeQajnWj04LwDyeU5pDHtQYgMJNRUQAP13%25P6RGNDIjAOihIQBzcKt3aJDW2aK0De2VrtGZH9urxRtetFOZ857M7K1RUgChCWR5GvlolZKgp2XHhrzv6jQ%25o6x2YDafHS6jmqn1%25Y5DyLOEfu%25qTJIs1S4L3uBrU0VJdSeZGjYuzVMRpD0SkNh56kMVA0ogYunNF4HvmsN0Kc%252y1J4Wxfj0pUcP81D4vlxbUEqc2189GsLx0bUiprJ8ihGw6ZuUw5ptYRSGtg67m5VpFxYCygN6K7mlTv0YhwyX324mIKTQdjcyBW3azDxTS1dnkq83KdzOALUdtzkIFJG4IQABKupciIFeWS6xybKMPVY8%25EWhbNmUfjPo90yGDvbHi4TpWI9%25wc3lkMiftxdXO%25w178zQZPtECUkaRJ7slGAna6CrXpFODulZQ6KIoqXRaYWDBEQ5nmPqFEagOybLssnvIT9JxOO2B3iubUIjedwShbBDMztM%25Qeqhk7hXaMLoACo6ThJHFlH7tou%25KX%25c6HSfWQfnU%25V1Pa1OkfNEbnEVT10s9Osp9E4riIxgoscZwB8%25rrxRteU3%25Z857MG6jRUgChpYD5Gvlo6UEgp2XHYGDv6jQ%25mpW2YDafy6ojmqn14LwDye8ix2Z8dQCnnvzgYZMhO30BSUz7sYXg9TjHdK8efW3DLJ',
  //       },
  //       {
  //         'id': 'bmw_m3_competition',
  //         'name': 'M3 Competition',
  //         'imageUrl':
  //             'https://prod.cosy.bmw.cloud/bmwweb/cosySec?COSY-EU-100-73317K9wt0u4fXu1ocL3hSntD0nBdKVZjYptn4Rp10t1gzBXQ2aK2m4qijmBYXGuSDOPLFtBZ8XVf0ZOKic1QgD%25ViPRKVZlPxK73DIdpvw3azDxDr0dnkq8qTszOALULuckIFJGJ7XABKupUBQFeWS6GwBKMPVYpeOWhbNm6ipPo90yYw2bHi4TnCt9%25wc3OmEiftxdIWCw178zB5qtECUkepZ7slGAM6uCrXpF7islZQ6KCZfXRaYWlRwQ5nmPXiUagOybQ%25ynvIT9aNSO2B3in0RIjedwOrABDMztIAzeqhk7B%25nMLoACeRvhJHFliJjou%25KXwrDHSfWQtZu%25V1Pa7IsfNEbnCxb10s9Ol8vE4riIXUqscZwBQGJrxRteaEzZ857Mns7RUgChOrN5Gvloqfcgp2XHLVGv6jQ%25JTZ2YDafu3bjmqn1SdiDyLOEVtpqTJIsN7CL3uBr0NMJdSeZ4btuzVMRcp9SkNh5x4rVA0og9ZoNF4Hvi330Kc%252wn44WxfjtEMcP81D7sVxbUEqUYV89GsLGSNUiprJpM%25Gw6Zu6QeptYRSYNO67m5Vm0EYCygNy7HmlDnEfbc1KVZiNV89RkBzcSktfoEE47BdqfKLjmBY0JuSDOPRQpSxIhkWExHS91Zys8%25P6EaV6lfNwEUnVI19mpzajeqKBtHenMA8PCzOSwNZxCRix2UT54ABNZvT1mvhAeX9xbZG7NgXA2Jf3KuvQnO',
  //       },
  //       {
  //         'id': 'bmw_z4_roadster',
  //         'name': 'Z4 Roadster',
  //         'imageUrl':
  //             'https://prod.cosy.bmw.cloud/bmwweb/cosySec?COSY-EU-100-73317K9wt0u4fXiYTgL3hL4CRf1xEaxQFCk89RbfKYmUrOpQhRVAfyq3VraezL14UDyeONayV%25OkaotUZ7WcMtECUkU227slGAzaKCrXpFkDulZQ6KAnkXRaYWFOYQ5nmPKI0agOybfCBnvIT9algO2B3in2ZIjedwOCYBDMztIG5eqhk7BNEMLoACeRMhJHFliNFou%25KXw0gHSfWQthX%25V1PaZlqfNEbnR2V10s9O589E4riIgUHscZwBvGkrxRte2FyZ857MjKWRUgChDjV5GvloTMPgp2XH3awv6OTib419Vo7xHoscCJzL1hJUbKiifGzqIbVBnvzg%25eMhO30CmRhEdFJNiEWhc972wsP05iyrdfbH8irTod9cvRLynkIVzUWkTAus0pL3h8H7EpCxEarjlfuzH7Qj9vQFukYcE47ZGHXYuaebDVMQmT3',
  //       },
  //     ],
  //   },
  //   // Mercedes-Benz Brand
  //   {
  //     'name': 'Mercedes-Benz',
  //     'logoUrl':
  //         'https://th.bing.com/th/id/OIP.2aBuavCtCzg_fu3a84M05AHaHa?w=163&h=180&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
  //     'models': [
  //       {
  //         'id': 'mercedes_glc',
  //         'name': 'GLC',
  //         'imageUrl':
  //             'https://media.oneweb.mercedes-benz.com/images/dynamic/asia/MY/254656/804_054/iris.png?q=COSY-EU-100-1713d0VXqaSFqtyO67PobzIr3eWsrrCsdRRzwQZUnRZbMw3SGtGyWtsd1HpcUfwOuXGEZ93J0lF6NOB2N8jbApjPbI5uVeZQC3qhrkzNR%25bm7jxymhKV1XQ%25vqwIdyLRZY2YaxF4hrH1dJZn8wf8foiZEioM4Fl4jTg92gk6PDp7bSeWuK2tsd3JVcUfNrkXGEjnRJ0lVDxOB2qWFbApUAbI5uG4YQC30h1kzNBlNm7jAODhKV5%25W%25vq4t9yLRgc6YaxPa9rH1eBln8wsQcoiZUMEM4FGTjTg9ozZ6PDC76SeWzKjtsd7YNcUfKM6XGEvTBJ0lLCxOB2azRbApHYbI5usouQC3UC1kzNGPZm7j0yvhKVBXM%25vqAujyLR5QyYaxCk8rH1zn%25n8w7oboiZKeEM4FvsJTg9LUT6PDaGDSeWH0Rtsd9h3cUfD%25kXGEWbSJ0lCohOB2zMObAp7ToI5uKMTQmIwlzkhQO9nm7jG2jhKVUXd%25vq7vlyLRKGDYaxv0JrH1LCtn8waz2oiZH6NM4F8SQTg9ih96PD4m2SeWgBVtsdRhQcUfxg7XGE0ymJ0lB0VOB2ABnbAp5iXI5uC4ZQC3zg7kzN7UNm7jKGDhKVvXF%25vGdeNQnF1WydaR7NEcqtyRV3H3k9kBF7v0wAFslUxnIeKS&imgt=P27&bkgnd=9&pov=BE040&uni=m&width=610&crop=',
  //       },
  //       {
  //         'id': 'mercedes_e_class',
  //         'name': 'E-Class',
  //         'imageUrl':
  //             'https://media.oneweb.mercedes-benz.com/images/dynamic/asia/MY/214050/804/iris.png?q=COSY-EU-100-1713d0VXqaWFqtyO67PobzIr3eWsrrCsdRRzwQZg9pZbMw3SGtxeFtsd1sbcUfp8cXGEuTRJ0l3ClOB2qBObApRPyI5uGoYQC30E3kzNHUum7j8yZhKViYh%25vqmBTyLRsGWYaxUbYrH1zJ1n8w7VxoiZKMXM4FvsJTg9Ukm6tTnuNpEAhKVHtc%25YhD3Lyr%25kf6YaxB0drH1LH1n8wa82oiZ4iYM4Fg4QTg9Pz36PDeLDSevjzFoJpENtjUTg%25q8WmtdDZGZMuMapgeLlHp7RKfJnzPk&BKGND=9&IMGT=P27&cp=U7lLKRUtPa6KAFr8s_ubHw&uni=m&POV=BE320',
  //       },
  //       {
  //         'id': 'mercedes_s_class',
  //         'name': 'S-Class',
  //         'imageUrl':
  //             'https://assets.oneweb.mercedes-benz.com/iris/iris.jpg?COSY-EU-100-1713d0VXqrWFqtyO67PobzIr3eWsrrCsdRRzwQZUnRZbMw3SGtlKStsd2HtcUfp80XGEubYJ0l36xOB2NS5bApjIXI5uVKIQC3qvWkzNwTbm7jZ6vhKVFKE%25vq9UTyLRDGmYaxWbSrH1KJ%25n8wvO4oiZLioM4FaKQTg9HtV6PD8%25bSeWiyMtsd4YtcUfC%25kXGEzG3J0l7IVOB2KQObApvdyI5uLfJQC3akOkzNHmdm7jgevhKVPs9%25vqeIDyLR5cyYaxCaWrH1zI1n8w7VxoiZK%25oM4FvywTg9L6O6PDaSoSeWHthtsd8BQcUfiAWXGEWbSJ0lCrnOIJtR1qNvoiZeIQM6o2xgTSMr3O6PDLkoSeWvK3tsdPvQcUfxFNXGE0ywJ0lB0tOB2ABnbAp5iwI5gZ8lXhRjwQZznwzKauoQ3pE77V9hDNt3DkSW9wUwopoL24PvEa2zq7DJ3D=&imgt=P27&bkgnd=9&pov=BE040&uni=m&width=610&crop=',
  //       },
  //       {
  //         'id': 'mercedes_a_class',
  //         'name': 'A-Class',
  //         'imageUrl':
  //             'https://assets.oneweb.mercedes-benz.com/iris/iris.png?COSY-EU-100-1713d0VXqNEFqtyO67PobzIr3eWsrrCsdRRzwQZg9pZbMw3SGtle9tsd2HdcUfp8qXGEunSJ0l3ofOB2NS1bApRTyI5uGoxQC30SpkzNHTwm7j871hKVi%25F%25vqmtjyLRhA6YaxU5drH1Gm%25n8w0XwoiZKbpM4FvyjTg9L6k6PDaGqSeWFyutsdB%25ycJtTjqNpzYax4JOroYfV8nMr%252coiZ76ZM4Fzm3Tg9itk6PDVEUSeWsKMtsdUvGcUfGLWXGE0nYJ0lBDtOBi1aftkV3xb1iN85uA2rbpldCCNZkFu6pFIT9ZxexrlrKE847dvE5jCFcpF=&imgt=P27&bkgnd=9&pov=BE040&uni=m&width=610&crop=',
  //       },
  //       {
  //         'id': 'mercedes_c_class',
  //         'name': 'C-Class',
  //         'imageUrl':
  //             'https://media.oneweb.mercedes-benz.com/images/dynamic/asia/MY/206042/804/iris.png?q=COSY-EU-100-1713d0VXqaWFqtyO67PobzIr3eWsrrCsdRRzwQZ6ZHZbMw3SGtle9tsd2HdcUfp8qXGEubmJ0l3ItOB2NQnbApjtwI5uVQDQC3qvTkzNwTVm7jZ7ZhKVFKh%25vq9UTyLRDO6Yax7NxrH1eJdn8wsTfoiZUMEM4FGTjTg9ovO6PDC%25uSeWz0Wtsd8hdcUfiFWXGE4JmJ0lgOtOB2PbnbApe7pI5usKDQC3vT6khQZ27m%25kbDohKV0XF%25vqGBIyLRKLRYaxvaErH1pC%25n8wi8yoiZ45YM4FgCuTg9Pv96PKNCZnX2f3SNsF6hdwDkSW9wUwopoL24PvEa2zq7dXrCgQ&imgt=P27&bkgnd=9&pov=BE040&uni=m&width=610&crop=',
  //       },
  //       {
  //         'id': 'mercedes_gls',
  //         'name': 'GLS',
  //         'imageUrl':
  //             'https://media.oneweb.mercedes-benz.com/images/dynamic/asia/MY/167959/805/iris.png?q=COSY-EU-100-1713d0VXq0WFqtyO67PobzIr3eWsrrCsdRRzwQZ6ZHZbMw3SGtlKUtsd2HtcUfpr6XGEu9BJ0l36xOB2NzFbApRAyI5uxKMQC30MrkzNBTbm7jA7mhKV50L%25vqCBlyLRzn2Yax7NYrH1KnOn8wsOfoiZUbXM4FG4fTg90tT6PDBSbSeWAtMtsd5cxcUfSLWXGEtbmJ0lLHJOB2a8RbApHPwI5u8cJQC3iXwkzNGT9m7j07ZhKVBYW%25vqArayLR5ORYaxCkxrH1zmin8w7oboiZKeEM4FvsjTg9LUZ6PDZkbSeWFmMtsdB%25ycJtj9GXOc6RBJ0lKoJOB2g8cbAp4TZI5uBo2QC3ACWkzN5Pwm7jCeohKVz0M%25vq7uqyLRlMdYaxHXSrH18JOn8wiA4oiZ451M4FgSlTg9P6n6PKNCZnX2f3SNKL7BVNDkSW9wUwopoL24PvEa2zq7dXrCgQ&imgt=P27&bkgnd=9&pov=BE040&uni=m&width=610&crop=',
  //       },
  //     ],
  //   },
  //   // Audi Brand
  //   {
  //     'name': 'Audi',
  //     'logoUrl':
  //         'https://th.bing.com/th/id/OIP.JNHUCrVj4u0674OR6wh9IgHaEK?w=296&h=180&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
  //     'models': [
  //       {
  //         'id': 'audi_a3',
  //         'name': 'A3',
  //         'imageUrl':
  //             'https://groupcms-services-api.porsche-holding.com/dam/images/a2aad1ae9da059f834de5d667184c63bf48acb64/34052ea3f373558bc14bca2c9ddad96d/2ae21e01-0b7b-4fc6-ae7a-5f0adbc672a8/crop:SMART/resize:384:165/thumbprozent202021png',
  //       },
  //       {
  //         'id': 'audi_a5',
  //         'name': 'A5',
  //         'imageUrl':
  //             'https://groupcms-services-api.porsche-holding.com/dam/images/c601d5664674b529fe8b7251a6f1c71473234538/d25ff0b3346d0e468977db3474590e45/3d6c2cc3-298a-4652-ad78-f6a24ede34c5/crop:SMART/resize:384:165/a5sportbackpng',
  //       },
  //       {
  //         'id': 'audi_a8l',
  //         'name': 'A8 L',
  //         'imageUrl':
  //             'https://groupcms-services-api.porsche-holding.com/dam/images/01b3f6ef40cd67b62c8305f9fa7017b235127801/4278dcf5bba37914e36a1d5c304003e8/1a8f18d7-00d8-4972-a10e-33697ab7d7e7/crop:SMART/resize:384:165/a8-l',
  //       },
  //       {
  //         'id': 'audi_q3_sportback',
  //         'name': 'Q3 Sportback',
  //         'imageUrl':
  //             'https://groupcms-services-api.porsche-holding.com/dam/images/3079c22d88c1958d6ba9874f22c72b65a2576f8f/5ec92f48b29818fb1cb968a4da52a812/76e134ee-8fe7-4c28-a04f-39d01d801ce6/crop:SMART/resize:384:165/q3png',
  //       },
  //       {
  //         'id': 'audi_q7',
  //         'name': 'Q7',
  //         'imageUrl':
  //             'https://groupcms-services-api.porsche-holding.com/dam/images/42ebcc1c4a5e2aae8702a4c207902b06a7839bb2/9c1e0c2f395dce43ebd1382c3191ce6f/4520287f-f666-4883-9218-c8caa472ca78/crop:SMART/resize:384:165/q7',
  //       },
  //       {
  //         'id': 'audi__rs_q8',
  //         'name': 'RS Q8',
  //         'imageUrl':
  //             'https://groupcms-services-api.porsche-holding.com/dam/images/17cf8ccbe10145007ec62cb978c434f0ac05500a/9342d23c9d5539bc21f41a54a7107231/63c63116-cca9-4c51-a451-35f11b3ab28e/crop:SMART/resize:384:165/q8png',
  //       },
  //     ],
  //   },
  //   // Nissan Brand
  //   {
  //     'name': 'Nissan',
  //     'logoUrl':
  //         'https://th.bing.com/th/id/OIP.UN0UYxAvWAGim_g8o_D2fAHaGr?w=208&h=187&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
  //     'models': [
  //       {
  //         'id': 'nissan_almera',
  //         'name': 'Almera',
  //         'imageUrl':
  //             'https://nissan.com.my/v2/wp-content/uploads/2024/07/vehicle-filter-4.png',
  //       },
  //       {
  //         'id': 'nissan_serena',
  //         'name': 'Serena',
  //         'imageUrl':
  //             'https://nissan.com.my/v2/wp-content/uploads/2024/07/vehicle-filter-2.png',
  //       },
  //       {
  //         'id': 'nissan_navara',
  //         'name': 'Navara',
  //         'imageUrl':
  //             'https://nissan.com.my/v2/wp-content/uploads/2024/07/vehicle-filter-3.png',
  //       },
  //       {
  //         'id': 'nissan_x_trail',
  //         'name': 'X-Trail',
  //         'imageUrl':
  //             'https://nissan.com.my/v2/wp-content/uploads/2024/07/vehicle-filter-5.png',
  //       },
  //       {
  //         'id': 'nissan_leaf',
  //         'name': 'Leaf',
  //         'imageUrl':
  //             'https://nissan.com.my/v2/wp-content/uploads/2024/07/vehicle-filter-1.png',
  //       },
  //       {
  //         'id': 'nissan_nv200',
  //         'name': 'NV200',
  //         'imageUrl':
  //             'https://nissan.com.my/v2/wp-content/uploads/2024/07/vehicle-filter-7.png',
  //       },
  //     ],
  //   },
  // ];

  // Future<void> addVehicleBrands() async {
  //   for (var brandData in vehicleBrandsData) {
  //     DocumentReference brandRef = await _vehicleBrandsCollection.add({
  //       'name': brandData['name'],
  //       'logoUrl': brandData['logoUrl'],
  //       'models': brandData['models'],
  //     });
  //   }
  // }
}
