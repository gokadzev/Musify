package com.malopieds.innertube.models

import kotlinx.serialization.Serializable

@Serializable
data class YouTubeClient(
    val clientName: String,
    val clientVersion: String,
    val clientId: String,
    val osVersion: String? = null,
    val api_key: String,
    val userAgent: String,
    val loginRequired: Boolean = false,
    val loginSupported: Boolean = false,
    val useSignatureTimestamp: Boolean = false,
    val isEmbedded: Boolean = false,
) {
    fun toContext(
        locale: YouTubeLocale,
        visitorData: String?,
    ) = Context(
        client =
            Context.Client(
                clientName = clientName,
                clientVersion = clientVersion,
                osVersion = osVersion,
                gl = locale.gl,
                hl = locale.hl,
                visitorData = visitorData,
            ),
    )

    companion object {
        const val ORIGIN_YOUTUBE_MUSIC = "https://music.youtube.com"
        const val REFERER_YOUTUBE_MUSIC = "$ORIGIN_YOUTUBE_MUSIC/"
        const val API_URL_YOUTUBE_MUSIC = "$ORIGIN_YOUTUBE_MUSIC/youtubei/v1/"

        const val USER_AGENT_WEB =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36"
        private const val USER_AGENT_ANDROID =
            "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Mobile Safari/537.36"
        private const val USER_AGENT_IOS = "com.google.ios.youtube/19.29.1 (iPhone16,2; U; CPU iOS 17_5_1 like Mac OS X;)"
        private const val USER_AGENT_TVHTML5 =
            "Mozilla/5.0 (PlayStation; PlayStation 4/12.00) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.4 Safari/605.1.15"

        val ANDROID_MUSIC =
            YouTubeClient(
                clientName = "ANDROID_MUSIC",
                clientVersion = "5.54.52",
                clientId = "21",
                api_key = "AIzaSyAOghZGza2MQSZkY_zfZ370N-PUdXEo8AI",
                userAgent = USER_AGENT_ANDROID,
            )

        val ANDROID =
            YouTubeClient(
                clientName = "ANDROID",
                clientVersion = "17.13.3",
                clientId = "3",
                api_key = "AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w",
                userAgent = USER_AGENT_ANDROID,
            )
        val IOS =
            YouTubeClient(
                clientName = "IOS",
                clientVersion = "19.45.4",
                clientId = "5",
                osVersion = "18.1.0.22B83",
                api_key = "AIzaSyB-63vPrdThhKuerbB2N_l7Kwwcxj6yUAc",
                userAgent = USER_AGENT_IOS,
            )
        val WEB =
            YouTubeClient(
                clientName = "WEB",
                clientVersion = "2.20241126.01.00",
                clientId = "1",
                api_key = "AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX3",
                userAgent = USER_AGENT_WEB,
            )

        val WEB_REMIX =
            YouTubeClient(
                clientName = "WEB_REMIX",
                clientVersion = "1.20241127.01.00",
                clientId = "67",
                api_key = "AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30",
                userAgent = USER_AGENT_WEB,
                loginSupported = true,
                useSignatureTimestamp = true,
            )

        val TVHTML5 =
            YouTubeClient(
                clientName = "TVHTML5_SIMPLY_EMBEDDED_PLAYER",
                clientVersion = "2.0",
                clientId = "85",
                api_key = "AIzaSyDCU8hByM-4DrUqRUYnGn-3llEO78bcxq8",
                userAgent = USER_AGENT_TVHTML5,
                loginSupported = true,
                loginRequired = true,
                useSignatureTimestamp = true,
                isEmbedded = true,
            )
        val MAIN_CLIENT = WEB_REMIX
    }
}
