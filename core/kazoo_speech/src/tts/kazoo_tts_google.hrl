-ifndef(KAZOO_TTS_GOOGLE_HRL).

-type audioEncoding() ::
    'AUDIO_ENCODING_UNSPECIFIED'
    | 'LINEAR16'
    | 'MP3'
    | 'OGG_OPUS'.

-type ssmlVoiceGender() ::
    'SSML_VOICE_GENDER_UNSPECIFIED'
    | 'MALE'
    | 'FEMALE'
    | 'NEUTRAL'.

-type speakingRate() :: float() | 'undefined'.
-type pitch() :: float() | 'undefined'.
-type volumeGainDb() :: float() | 'undefined'.
-type sampleRateHertz() :: pos_integer() | 'undefined'.

-record(synthesisInput, {
    text :: kz_term:api_ne_binary(),
    ssml :: kz_term:api_ne_binary()
}).

-record(voiceSelectionParams, {
    languageCode = <<"en-US">> :: kz_term:api_ne_binary(),
    name :: kz_term:api_ne_binary(),
    ssmlGender :: ssmlVoiceGender() | 'undefined'
}).

-record(audioConfig, {
    audioEncoding = 'LINEAR16' :: audioEncoding(),
    speakingRate :: speakingRate() | 'undefined',
    pitch :: pitch() | 'undefined',
    volumeGainDb :: volumeGainDb() | 'undefined',
    sampleRateHertz :: sampleRateHertz() | 'undefined'
}).

-type synthesisInput() :: #synthesisInput{}.
-type voiceSelectionParams() :: #voiceSelectionParams{}.
-type audioConfig() :: #audioConfig{}.

-define(GOOGLE_FORMAT_MAPPINGS, [
    {<<"wav">>, 'LINEAR16'},
    {<<"mp3">>, 'MP3'}
]).

-define(GOOGLE_TO_CONTENT_TYPE_MAPPINGS, [
    {'LINEAR16', <<"audio/wav">>},
    {'MP3', <<"audio/mpeg">>}
]).

-record(voiceDesc, {
    name :: kz_term:ne_binary(),
    ssmlGender :: kz_term:ne_binary(),
    naturalSampleRateHertz :: non_neg_integer(),
    languageCodes :: kz_term:ne_binaries()
}).

%% this mapping may be generated by curl and jq utility
%% https://stedolan.github.io/jq/
%% command
%%  curl -s -S  -H "X-Goog-Api-Key: YOUR-TOKEN-HERE" \
%%              -H "Content-Type: application/json; charset=utf-8" \
%%              "https://texttospeech.googleapis.com/v1/voices"  | \
%%   jq -j '.voices | map(@text "        ,#voiceDesc{name = <<\"\(.name)\">>, ssmlGender = <<\"\(.ssmlGender)\">>, naturalSampleRateHertz = \(.naturalSampleRateHertz), languageCodes = [<<\"\(.languageCodes | join("\">>,<<\"") )\">>]}") | join("\n")'

-define(GOOGLE_TTS_VOICE_MAPPINGS, [
    #voiceDesc{
        name = <<"es-ES-Standard-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"es-ES">>]
    },
    #voiceDesc{
        name = <<"it-IT-Standard-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"it-IT">>]
    },
    #voiceDesc{
        name = <<"ja-JP-Standard-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 22050,
        languageCodes = [<<"ja-JP">>]
    },
    #voiceDesc{
        name = <<"ko-KR-Standard-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 22050,
        languageCodes = [<<"ko-KR">>]
    },
    #voiceDesc{
        name = <<"pt-BR-Standard-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"pt-BR">>]
    },
    #voiceDesc{
        name = <<"tr-TR-Standard-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 22050,
        languageCodes = [<<"tr-TR">>]
    },
    #voiceDesc{
        name = <<"sv-SE-Standard-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 22050,
        languageCodes = [<<"sv-SE">>]
    },
    #voiceDesc{
        name = <<"nl-NL-Standard-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"nl-NL">>]
    },
    #voiceDesc{
        name = <<"en-US-Wavenet-D">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-US">>]
    },
    #voiceDesc{
        name = <<"de-DE-Wavenet-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"de-DE">>]
    },
    #voiceDesc{
        name = <<"de-DE-Wavenet-B">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"de-DE">>]
    },
    #voiceDesc{
        name = <<"de-DE-Wavenet-C">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"de-DE">>]
    },
    #voiceDesc{
        name = <<"de-DE-Wavenet-D">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"de-DE">>]
    },
    #voiceDesc{
        name = <<"en-AU-Wavenet-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-AU">>]
    },
    #voiceDesc{
        name = <<"en-AU-Wavenet-B">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-AU">>]
    },
    #voiceDesc{
        name = <<"en-AU-Wavenet-C">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-AU">>]
    },
    #voiceDesc{
        name = <<"en-AU-Wavenet-D">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-AU">>]
    },
    #voiceDesc{
        name = <<"en-GB-Wavenet-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-GB">>]
    },
    #voiceDesc{
        name = <<"en-GB-Wavenet-B">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-GB">>]
    },
    #voiceDesc{
        name = <<"en-GB-Wavenet-C">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-GB">>]
    },
    #voiceDesc{
        name = <<"en-GB-Wavenet-D">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-GB">>]
    },
    #voiceDesc{
        name = <<"en-US-Wavenet-A">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-US">>]
    },
    #voiceDesc{
        name = <<"en-US-Wavenet-B">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-US">>]
    },
    #voiceDesc{
        name = <<"en-US-Wavenet-C">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-US">>]
    },
    #voiceDesc{
        name = <<"en-US-Wavenet-E">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-US">>]
    },
    #voiceDesc{
        name = <<"en-US-Wavenet-F">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-US">>]
    },
    #voiceDesc{
        name = <<"fr-FR-Wavenet-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"fr-FR">>]
    },
    #voiceDesc{
        name = <<"fr-FR-Wavenet-B">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"fr-FR">>]
    },
    #voiceDesc{
        name = <<"fr-FR-Wavenet-C">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"fr-FR">>]
    },
    #voiceDesc{
        name = <<"fr-FR-Wavenet-D">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"fr-FR">>]
    },
    #voiceDesc{
        name = <<"it-IT-Wavenet-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"it-IT">>]
    },
    #voiceDesc{
        name = <<"ja-JP-Wavenet-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"ja-JP">>]
    },
    #voiceDesc{
        name = <<"nl-NL-Wavenet-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"nl-NL">>]
    },
    #voiceDesc{
        name = <<"en-GB-Standard-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-GB">>]
    },
    #voiceDesc{
        name = <<"en-GB-Standard-B">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-GB">>]
    },
    #voiceDesc{
        name = <<"en-GB-Standard-C">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-GB">>]
    },
    #voiceDesc{
        name = <<"en-GB-Standard-D">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-GB">>]
    },
    #voiceDesc{
        name = <<"en-US-Standard-B">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-US">>]
    },
    #voiceDesc{
        name = <<"en-US-Standard-C">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-US">>]
    },
    #voiceDesc{
        name = <<"en-US-Standard-D">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-US">>]
    },
    #voiceDesc{
        name = <<"en-US-Standard-E">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-US">>]
    },
    #voiceDesc{
        name = <<"de-DE-Standard-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"de-DE">>]
    },
    #voiceDesc{
        name = <<"de-DE-Standard-B">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"de-DE">>]
    },
    #voiceDesc{
        name = <<"en-AU-Standard-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-AU">>]
    },
    #voiceDesc{
        name = <<"en-AU-Standard-B">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-AU">>]
    },
    #voiceDesc{
        name = <<"en-AU-Standard-C">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-AU">>]
    },
    #voiceDesc{
        name = <<"en-AU-Standard-D">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"en-AU">>]
    },
    #voiceDesc{
        name = <<"fr-CA-Standard-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"fr-CA">>]
    },
    #voiceDesc{
        name = <<"fr-CA-Standard-B">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"fr-CA">>]
    },
    #voiceDesc{
        name = <<"fr-CA-Standard-C">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"fr-CA">>]
    },
    #voiceDesc{
        name = <<"fr-CA-Standard-D">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"fr-CA">>]
    },
    #voiceDesc{
        name = <<"fr-FR-Standard-A">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"fr-FR">>]
    },
    #voiceDesc{
        name = <<"fr-FR-Standard-B">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"fr-FR">>]
    },
    #voiceDesc{
        name = <<"fr-FR-Standard-C">>,
        ssmlGender = <<"FEMALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"fr-FR">>]
    },
    #voiceDesc{
        name = <<"fr-FR-Standard-D">>,
        ssmlGender = <<"MALE">>,
        naturalSampleRateHertz = 24000,
        languageCodes = [<<"fr-FR">>]
    }
]).

-define(GOOGLE_CONFIG_CAT, <<(?MOD_CONFIG_CAT)/binary, ".google">>).
-define(GOOGLE_TTS_URL,
    kapps_config:get_string(
        ?GOOGLE_CONFIG_CAT,
        <<"tts_url">>,
        <<"https://texttospeech.googleapis.com/v1/text:synthesize">>
    )
).
-define(GOOGLE_TTS_KEY, kapps_config:get_binary(?GOOGLE_CONFIG_CAT, <<"tts_api_key">>, <<>>)).

-define(KAZOO_TTS_GOOGLE_HRL, 'true').
-endif.
