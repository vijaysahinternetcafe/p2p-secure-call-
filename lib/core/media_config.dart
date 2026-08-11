class MediaConfig {
  Map<String, dynamic> get offerConstraints => {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
      'IceRestart': true,
    },
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
      {'googImprovedWifiBwe': true},
      {'googHighpassFilter': true},
      {'googEchoCancellation': true},
      {'googNoiseSuppression': true},
      {'googAutoGainControl': true},
    ],
  };

  Map<String, dynamic> get answerConstraints => {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };
}

