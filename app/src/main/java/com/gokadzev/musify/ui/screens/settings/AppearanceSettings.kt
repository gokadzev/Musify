package com.gokadzev.musify.ui.screens.settings

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.gokadzev.musify.LocalPlayerAwareWindowInsets
import com.gokadzev.musify.R
import com.gokadzev.musify.constants.DarkModeKey
import com.gokadzev.musify.constants.DefaultOpenTabKey
import com.gokadzev.musify.constants.DynamicThemeKey
import com.gokadzev.musify.constants.GridItemSize
import com.gokadzev.musify.constants.GridItemsSizeKey
import com.gokadzev.musify.constants.LyricsClickKey
import com.gokadzev.musify.constants.LyricsTextPositionKey
import com.gokadzev.musify.constants.PlayerBackgroundStyle
import com.gokadzev.musify.constants.PlayerBackgroundStyleKey
import com.gokadzev.musify.constants.PlayerTextAlignmentKey
import com.gokadzev.musify.constants.PureBlackKey
import com.gokadzev.musify.constants.SliderStyle
import com.gokadzev.musify.constants.SliderStyleKey
import com.gokadzev.musify.constants.SwipeThumbnailKey
import com.gokadzev.musify.ui.component.DefaultDialog
import com.gokadzev.musify.ui.component.EnumListPreference
import com.gokadzev.musify.ui.component.IconButton
import com.gokadzev.musify.ui.component.PreferenceEntry
import com.gokadzev.musify.ui.component.PreferenceGroup
import com.gokadzev.musify.ui.component.PreferenceGroupTitle
import com.gokadzev.musify.ui.component.SwitchPreference
import com.gokadzev.musify.ui.utils.backToMain
import com.gokadzev.musify.utils.rememberEnumPreference
import com.gokadzev.musify.utils.rememberPreference
import me.saket.squiggles.SquigglySlider

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppearanceSettings(
    navController: NavController,
    scrollBehavior: TopAppBarScrollBehavior,
) {
    val (dynamicTheme, onDynamicThemeChange) = rememberPreference(DynamicThemeKey, defaultValue = true)
    val (darkMode, onDarkModeChange) = rememberEnumPreference(DarkModeKey, defaultValue = DarkMode.AUTO)
    val (playerBackground, onPlayerBackgroundChange) =
        rememberEnumPreference(
            PlayerBackgroundStyleKey,
            defaultValue = PlayerBackgroundStyle.DEFAULT,
        )
    val (pureBlack, onPureBlackChange) = rememberPreference(PureBlackKey, defaultValue = false)
    val (defaultOpenTab, onDefaultOpenTabChange) = rememberEnumPreference(DefaultOpenTabKey, defaultValue = NavigationTab.HOME)
    val (lyricsPosition, onLyricsPositionChange) = rememberEnumPreference(LyricsTextPositionKey, defaultValue = LyricsPosition.CENTER)
    val (playerTextAlignment, onPlayerTextAlignmentChange) =
        rememberEnumPreference(
            PlayerTextAlignmentKey,
            defaultValue = PlayerTextAlignment.CENTER,
        )
    val (lyricsClick, onLyricsClickChange) = rememberPreference(LyricsClickKey, defaultValue = true)
    val (sliderStyle, onSliderStyleChange) = rememberEnumPreference(SliderStyleKey, defaultValue = SliderStyle.DEFAULT)
    val (swipeThumbnail, onSwipeThumbnailChange) = rememberPreference(SwipeThumbnailKey, defaultValue = true)
    val (gridItemSize, onGridItemSizeChange) = rememberEnumPreference(GridItemsSizeKey, defaultValue = GridItemSize.BIG)

    val isSystemInDarkTheme = isSystemInDarkTheme()
    val useDarkTheme =
        remember(darkMode, isSystemInDarkTheme) {
            if (darkMode == DarkMode.AUTO) isSystemInDarkTheme else darkMode == DarkMode.ON
        }

    var showSliderOptionDialog by rememberSaveable {
        mutableStateOf(false)
    }

    if (showSliderOptionDialog) {
        DefaultDialog(
            buttons = {
                TextButton(
                    onClick = { showSliderOptionDialog = false },
                ) {
                    Text(text = stringResource(android.R.string.cancel))
                }
            },
            onDismiss = {
                showSliderOptionDialog = false
            },
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                    modifier =
                        Modifier
                            .aspectRatio(1f)
                            .weight(1f)
                            .clip(RoundedCornerShape(16.dp))
                            .border(
                                1.dp,
                                if (sliderStyle ==
                                    SliderStyle.DEFAULT
                                ) {
                                    MaterialTheme.colorScheme.primary
                                } else {
                                    MaterialTheme.colorScheme.outlineVariant
                                },
                                RoundedCornerShape(16.dp),
                            ).clickable {
                                onSliderStyleChange(SliderStyle.DEFAULT)
                                showSliderOptionDialog = false
                            }.padding(16.dp),
                ) {
                    var sliderValue by remember {
                        mutableFloatStateOf(0.5f)
                    }
                    Slider(
                        value = sliderValue,
                        valueRange = 0f..1f,
                        onValueChange = {
                            sliderValue = it
                        },
                        modifier =
                            Modifier
                                .weight(1f)
                                .pointerInput(Unit) {
                                    detectTapGestures(
                                        onPress = {},
                                    )
                                },
                    )

                    Text(
                        text = stringResource(R.string.default_),
                        style = MaterialTheme.typography.labelLarge,
                    )
                }
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                    modifier =
                        Modifier
                            .aspectRatio(1f)
                            .weight(1f)
                            .clip(RoundedCornerShape(16.dp))
                            .border(
                                1.dp,
                                if (sliderStyle ==
                                    SliderStyle.SQUIGGLY
                                ) {
                                    MaterialTheme.colorScheme.primary
                                } else {
                                    MaterialTheme.colorScheme.outlineVariant
                                },
                                RoundedCornerShape(16.dp),
                            ).clickable {
                                onSliderStyleChange(SliderStyle.SQUIGGLY)
                                showSliderOptionDialog = false
                            }.padding(16.dp),
                ) {
                    var sliderValue by remember {
                        mutableFloatStateOf(0.5f)
                    }
                    SquigglySlider(
                        value = sliderValue,
                        valueRange = 0f..1f,
                        onValueChange = {
                            sliderValue = it
                        },
                        modifier = Modifier.weight(1f),
                    )

                    Text(
                        text = stringResource(R.string.squiggly),
                        style = MaterialTheme.typography.labelLarge,
                    )
                }
            }
        }
    }

    Column(
        Modifier
            .windowInsetsPadding(LocalPlayerAwareWindowInsets.current.only(WindowInsetsSides.Horizontal + WindowInsetsSides.Bottom))
            .verticalScroll(rememberScrollState()),
    ) {
        Spacer(Modifier.windowInsetsPadding(LocalPlayerAwareWindowInsets.current.only(WindowInsetsSides.Top)))

        PreferenceGroupTitle(
            title = stringResource(R.string.theme),
        )
        PreferenceGroup {
            SwitchPreference(
                title = { Text(stringResource(R.string.enable_dynamic_theme)) },
                icon = { Icon(painterResource(R.drawable.palette), null) },
                checked = dynamicTheme,
                onCheckedChange = onDynamicThemeChange,
                isFirstInGroup = true,
            )

            EnumListPreference(
                title = { Text(stringResource(R.string.dark_theme)) },
                icon = { Icon(painterResource(R.drawable.dark_mode), null) },
                selectedValue = darkMode,
                onValueSelected = onDarkModeChange,
                isLastInGroup = true,
                valueText = {
                    when (it) {
                        DarkMode.ON -> stringResource(R.string.dark_theme_on)
                        DarkMode.OFF -> stringResource(R.string.dark_theme_off)
                        DarkMode.AUTO -> stringResource(R.string.dark_theme_follow_system)
                    }
                },
            )

            AnimatedVisibility(useDarkTheme) {
                SwitchPreference(
                    title = { Text(stringResource(R.string.pure_black)) },
                    icon = { Icon(painterResource(R.drawable.contrast), null) },
                    checked = pureBlack,
                    onCheckedChange = onPureBlackChange,
                )
            }
        }

        PreferenceGroupTitle(
            title = stringResource(R.string.player),
        )

        PreferenceGroup {
            EnumListPreference(
                title = { Text(stringResource(R.string.player_background_style)) },
                icon = { Icon(painterResource(R.drawable.gradient), null) },
                selectedValue = playerBackground,
                onValueSelected = onPlayerBackgroundChange,
                isFirstInGroup = true,
                valueText = {
                    when (it) {
                        PlayerBackgroundStyle.DEFAULT -> stringResource(R.string.follow_theme)
                        PlayerBackgroundStyle.GRADIENT -> stringResource(R.string.gradient)
                    }
                },
            )

            PreferenceEntry(
                title = { Text(stringResource(R.string.player_slider_style)) },
                description =
                    when (sliderStyle) {
                        SliderStyle.DEFAULT -> stringResource(R.string.default_)
                        SliderStyle.SQUIGGLY -> stringResource(R.string.squiggly)
                    },
                icon = { Icon(painterResource(R.drawable.sliders), null) },
                onClick = {
                    showSliderOptionDialog = true
                },
            )

            SwitchPreference(
                title = { Text(stringResource(R.string.enable_swipe_thumbnail)) },
                icon = { Icon(painterResource(R.drawable.swipe), null) },
                checked = swipeThumbnail,
                onCheckedChange = onSwipeThumbnailChange,
            )

            EnumListPreference(
                title = { Text(stringResource(R.string.player_text_alignment)) },
                icon = {
                    Icon(
                        painter =
                            painterResource(
                                when (playerTextAlignment) {
                                    PlayerTextAlignment.CENTER -> R.drawable.format_align_center
                                    PlayerTextAlignment.SIDED -> R.drawable.format_align_left
                                },
                            ),
                        contentDescription = null,
                    )
                },
                selectedValue = playerTextAlignment,
                onValueSelected = onPlayerTextAlignmentChange,
                valueText = {
                    when (it) {
                        PlayerTextAlignment.SIDED -> stringResource(R.string.sided)
                        PlayerTextAlignment.CENTER -> stringResource(R.string.center)
                    }
                },
            )

            EnumListPreference(
                title = { Text(stringResource(R.string.lyrics_text_position)) },
                icon = { Icon(painterResource(R.drawable.lyrics), null) },
                selectedValue = lyricsPosition,
                onValueSelected = onLyricsPositionChange,
                valueText = {
                    when (it) {
                        LyricsPosition.LEFT -> stringResource(R.string.left)
                        LyricsPosition.CENTER -> stringResource(R.string.center)
                        LyricsPosition.RIGHT -> stringResource(R.string.right)
                    }
                },
            )

            SwitchPreference(
                title = { Text(stringResource(R.string.lyrics_click_change)) },
                icon = { Icon(painterResource(R.drawable.lyrics), null) },
                checked = lyricsClick,
                onCheckedChange = onLyricsClickChange,
                isLastInGroup = true,
            )
        }

        PreferenceGroupTitle(
            title = stringResource(R.string.misc),
        )
        PreferenceGroup {
            EnumListPreference(
            title = { Text(stringResource(R.string.default_open_tab)) },
            icon = { Icon(painterResource(R.drawable.tab), null) },
            selectedValue = defaultOpenTab,
            onValueSelected = onDefaultOpenTabChange,
            isFirstInGroup = true,
            valueText = {
                when (it) {
                NavigationTab.HOME -> stringResource(R.string.home)
                NavigationTab.EXPLORE -> stringResource(R.string.explore)
                NavigationTab.LIBRARY -> stringResource(R.string.filter_library)
                }
            },
            )

            EnumListPreference(
            title = { Text(stringResource(R.string.grid_cell_size)) },
            icon = { Icon(painterResource(R.drawable.grid_view), null) },
            selectedValue = gridItemSize,
            onValueSelected = onGridItemSizeChange,
            isLastInGroup = true,
            valueText = {
                when (it) {
                GridItemSize.SMALL -> stringResource(R.string.small)
                GridItemSize.BIG -> stringResource(R.string.big)
                }
            },
            )
        }

        Spacer(modifier = Modifier.padding(bottom = 16.dp))
    }

    TopAppBar(
        title = { Text(stringResource(R.string.appearance)) },
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

enum class DarkMode {
    ON,
    OFF,
    AUTO,
}

enum class NavigationTab {
    HOME,
    EXPLORE,
    LIBRARY,
}

enum class LyricsPosition {
    LEFT,
    CENTER,
    RIGHT,
}

enum class PlayerTextAlignment {
    SIDED,
    CENTER,
}
