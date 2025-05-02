package com.malopieds.innertune.ui.screens.settings

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.navigation.NavController
import com.malopieds.innertube.utils.parseCookieString
import com.malopieds.innertune.LocalPlayerAwareWindowInsets
import com.malopieds.innertune.R
import com.malopieds.innertune.constants.AccountChannelHandleKey
import com.malopieds.innertune.constants.AccountEmailKey
import com.malopieds.innertune.constants.AccountNameKey
import com.malopieds.innertune.constants.ChipSortTypeKey
import com.malopieds.innertune.constants.ContentCountryKey
import com.malopieds.innertune.constants.ContentLanguageKey
import com.malopieds.innertune.constants.CountryCodeToName
import com.malopieds.innertune.constants.HideExplicitKey
import com.malopieds.innertune.constants.HistoryDuration
import com.malopieds.innertune.constants.InnerTubeCookieKey
import com.malopieds.innertune.constants.LanguageCodeToName
import com.malopieds.innertune.constants.LibraryFilter
import com.malopieds.innertune.constants.ProxyEnabledKey
import com.malopieds.innertune.constants.ProxyTypeKey
import com.malopieds.innertune.constants.ProxyUrlKey
import com.malopieds.innertune.constants.QuickPicks
import com.malopieds.innertune.constants.QuickPicksKey
import com.malopieds.innertune.constants.SYSTEM_DEFAULT
import com.malopieds.innertune.constants.SimilarContent
import com.malopieds.innertune.constants.TopSize
import com.malopieds.innertune.ui.component.EditTextPreference
import com.malopieds.innertune.ui.component.IconButton
import com.malopieds.innertune.ui.component.ListPreference
import com.malopieds.innertune.ui.component.PreferenceEntry
import com.malopieds.innertune.ui.component.PreferenceGroupTitle
import com.malopieds.innertune.ui.component.SliderPreference
import com.malopieds.innertune.ui.component.SwitchPreference
import com.malopieds.innertune.ui.utils.backToMain
import com.malopieds.innertune.utils.rememberEnumPreference
import com.malopieds.innertune.utils.rememberPreference
import java.net.Proxy

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ContentSettings(
    navController: NavController,
    scrollBehavior: TopAppBarScrollBehavior,
) {
    val context = LocalContext.current
    val accountName by rememberPreference(AccountNameKey, "")
    val accountEmail by rememberPreference(AccountEmailKey, "")
    val accountChannelHandle by rememberPreference(AccountChannelHandleKey, "")
    val innerTubeCookie by rememberPreference(InnerTubeCookieKey, "")
    val isLoggedIn =
        remember(innerTubeCookie) {
            "SAPISID" in parseCookieString(innerTubeCookie)
        }
    val (contentLanguage, onContentLanguageChange) = rememberPreference(key = ContentLanguageKey, defaultValue = "system")
    val (contentCountry, onContentCountryChange) = rememberPreference(key = ContentCountryKey, defaultValue = "system")
    val (hideExplicit, onHideExplicitChange) = rememberPreference(key = HideExplicitKey, defaultValue = false)
    val (proxyEnabled, onProxyEnabledChange) = rememberPreference(key = ProxyEnabledKey, defaultValue = false)
    val (proxyType, onProxyTypeChange) = rememberEnumPreference(key = ProxyTypeKey, defaultValue = Proxy.Type.HTTP)
    val (proxyUrl, onProxyUrlChange) = rememberPreference(key = ProxyUrlKey, defaultValue = "host:port")
    val (lengthTop, onLengthTopChange) = rememberPreference(key = TopSize, defaultValue = "50")
    val (historyDuration, onHistoryDurationChange) = rememberPreference(key = HistoryDuration, defaultValue = 30f)
    val (defaultChip, onDefaultChipChange) = rememberEnumPreference(key = ChipSortTypeKey, defaultValue = LibraryFilter.LIBRARY)
    val (quickPicks, onQuickPicksChange) = rememberEnumPreference(key = QuickPicksKey, defaultValue = QuickPicks.QUICK_PICKS)
    val (similarContentEnabled, similarContentEnabledChange) = rememberPreference(key = SimilarContent, defaultValue = true)

    Column(
        Modifier
            .windowInsetsPadding(LocalPlayerAwareWindowInsets.current.only(WindowInsetsSides.Horizontal + WindowInsetsSides.Bottom))
            .verticalScroll(rememberScrollState()),
    ) {
        Spacer(Modifier.windowInsetsPadding(LocalPlayerAwareWindowInsets.current.only(WindowInsetsSides.Top)))

        PreferenceEntry(
            title = { Text(if (isLoggedIn) accountName else stringResource(R.string.login)) },
            description =
                if (isLoggedIn) {
                    accountEmail.takeIf { it.isNotEmpty() }
                        ?: accountChannelHandle.takeIf { it.isNotEmpty() }
                } else {
                    null
                },
            icon = { Icon(painterResource(R.drawable.person), null) },
            onClick = { navController.navigate("login") },
        )

        ListPreference(
            title = { Text(stringResource(R.string.content_language)) },
            icon = { Icon(painterResource(R.drawable.language), null) },
            selectedValue = contentLanguage,
            values = listOf(SYSTEM_DEFAULT) + LanguageCodeToName.keys.toList(),
            valueText = {
                LanguageCodeToName.getOrElse(it) {
                    stringResource(R.string.system_default)
                }
            },
            onValueSelected = onContentLanguageChange,
        )
        ListPreference(
            title = { Text(stringResource(R.string.content_country)) },
            icon = { Icon(painterResource(R.drawable.location_on), null) },
            selectedValue = contentCountry,
            values = listOf(SYSTEM_DEFAULT) + CountryCodeToName.keys.toList(),
            valueText = {
                CountryCodeToName.getOrElse(it) {
                    stringResource(R.string.system_default)
                }
            },
            onValueSelected = onContentCountryChange,
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            PreferenceEntry(
                title = { Text(stringResource(R.string.app_language)) },
                description = stringResource(R.string.configure_app_language),
                icon = { Icon(painterResource(R.drawable.language), null) },
                onClick = {
                    try {
                        context.startActivity(
                            Intent(Settings.ACTION_APPLICATION_SETTINGS, Uri.parse("package:${context.packageName}")),
                        )
                    } catch (e: ActivityNotFoundException) {
                        Toast.makeText(context, R.string.intent_app_language_not_found, Toast.LENGTH_LONG).show()
                    }
                },
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PreferenceEntry(
                title = { Text(stringResource(R.string.open_supported_links)) },
                description = stringResource(R.string.configure_supported_links),
                icon = { Icon(painterResource(R.drawable.add_link), null) },
                onClick = {
                    try {
                        context.startActivity(
                            Intent(Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS, Uri.parse("package:${context.packageName}")),
                        )
                    } catch (e: ActivityNotFoundException) {
                        Toast.makeText(context, R.string.intent_supported_links_not_found, Toast.LENGTH_LONG).show()
                    }
                },
            )
        }

        SwitchPreference(
            title = { Text(stringResource(R.string.hide_explicit)) },
            icon = { Icon(painterResource(R.drawable.explicit), null) },
            checked = hideExplicit,
            onCheckedChange = onHideExplicitChange,
        )

        PreferenceGroupTitle(
            title = stringResource(R.string.proxy),
        )

        SwitchPreference(
            title = { Text(stringResource(R.string.enable_proxy)) },
            icon = { Icon(painterResource(R.drawable.wifi_proxy), null) },
            checked = proxyEnabled,
            onCheckedChange = onProxyEnabledChange,
        )

        AnimatedVisibility(proxyEnabled) {
            Column {
                ListPreference(
                    title = { Text(stringResource(R.string.proxy_type)) },
                    selectedValue = proxyType,
                    values = listOf(Proxy.Type.HTTP, Proxy.Type.SOCKS),
                    valueText = { it.name },
                    onValueSelected = onProxyTypeChange,
                )
                EditTextPreference(
                    title = { Text(stringResource(R.string.proxy_url)) },
                    value = proxyUrl,
                    onValueChange = onProxyUrlChange,
                )
            }
        }

        EditTextPreference(
            title = { Text(stringResource(R.string.top_length)) },
            value = lengthTop,
            isInputValid = {
                val number = it.toIntOrNull()
                number != null && it.isNotEmpty() && number > 0
            },
            onValueChange = onLengthTopChange,
        )

        ListPreference(
            title = { Text(stringResource(R.string.default_lib_chips)) },
            selectedValue = defaultChip,
            values =
                listOf(
                    LibraryFilter.LIBRARY,
                    LibraryFilter.PLAYLISTS,
                    LibraryFilter.SONGS,
                    LibraryFilter.ALBUMS,
                    LibraryFilter.ARTISTS,
                ),
            valueText = {
                when (it) {
                    LibraryFilter.SONGS -> stringResource(R.string.songs)
                    LibraryFilter.ARTISTS -> stringResource(R.string.artists)
                    LibraryFilter.ALBUMS -> stringResource(R.string.albums)
                    LibraryFilter.PLAYLISTS -> stringResource(R.string.playlists)
                    LibraryFilter.LIBRARY -> stringResource(R.string.filter_library)
                }
            },
            onValueSelected = onDefaultChipChange,
        )

        ListPreference(
            title = { Text(stringResource(R.string.set_quick_picks)) },
            selectedValue = quickPicks,
            values = listOf(QuickPicks.QUICK_PICKS, QuickPicks.LAST_LISTEN),
            valueText = {
                when (it) {
                    QuickPicks.QUICK_PICKS -> stringResource(R.string.quick_picks)
                    QuickPicks.LAST_LISTEN -> stringResource(R.string.last_song_listened)
                }
            },
            onValueSelected = onQuickPicksChange,
        )

        SliderPreference(
            title = { Text(stringResource(R.string.history_duration)) },
            value = historyDuration,
            onValueChange = onHistoryDurationChange,
        )

        SwitchPreference(
            title = { Text(stringResource(R.string.enable_similar_content)) },
            checked = similarContentEnabled,
            onCheckedChange = similarContentEnabledChange,
        )
    }

    TopAppBar(
        title = { Text(stringResource(R.string.content)) },
        navigationIcon = {
            IconButton(
                onClick = navController::navigateUp,
                onLongClick = navController::backToMain,
            ) {
                Icon(
                    painterResource(R.drawable.arrow_back),
                    contentDescription = null,
                )
            }
        },
    )
}
