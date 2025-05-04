package com.gokadzev.musify.ui.component

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ProvideTextStyle
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Slider
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.DialogProperties
import com.gokadzev.musify.R
import kotlin.math.roundToInt


@Composable
fun PreferenceEntry(
    modifier: Modifier = Modifier,
    title: @Composable () -> Unit,
    description: String? = null,
    content: (@Composable () -> Unit)? = null,
    icon: (@Composable () -> Unit)? = null,
    trailingContent: (@Composable () -> Unit)? = null,
    onClick: (() -> Unit)? = null,
    isEnabled: Boolean = true,
    isFirstInGroup: Boolean = false,
    isLastInGroup: Boolean = false,
) {
    val cornerRadius = 16.dp

    val shape = when {
        isFirstInGroup && isLastInGroup -> RoundedCornerShape(cornerRadius)
        isFirstInGroup -> RoundedCornerShape(
            topStart = cornerRadius,
            topEnd = cornerRadius,
            bottomStart = 0.dp,
            bottomEnd = 0.dp
        )
        isLastInGroup -> RoundedCornerShape(
            topStart = 0.dp,
            topEnd = 0.dp,
            bottomStart = cornerRadius,
            bottomEnd = cornerRadius
        )
        else -> RectangleShape
    }

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .background(
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
                shape = shape
            )
            .clip(shape)
            .clickable(
                enabled = isEnabled && onClick != null,
                onClick = onClick ?: {},
            )
            .alpha(if (isEnabled) 1f else 0.5f)
            .padding(horizontal = 16.dp, vertical = 16.dp),
    ) {
        if (icon != null) {
            Box(
                modifier = Modifier
                    .padding(end = 16.dp)
                    .size(24.dp),
                contentAlignment = Alignment.Center
            ) {
                icon()
            }
        }

        Column(
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.weight(1f),
        ) {
            ProvideTextStyle(MaterialTheme.typography.titleMedium) {
                title()
            }

            if (description != null) {
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            content?.invoke()
        }

        if (trailingContent != null) {
            Spacer(Modifier.width(12.dp))
            trailingContent()
        }
    }
}


@Composable
fun PreferenceGroup(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        content()
    }
}

@Composable
fun <T> ListPreference(
    modifier: Modifier = Modifier,
    title: @Composable () -> Unit,
    icon: (@Composable () -> Unit)? = null,
    selectedValue: T,
    values: List<T>,
    valueText: @Composable (T) -> String,
    onValueSelected: (T) -> Unit,
    isEnabled: Boolean = true,
    isFirstInGroup: Boolean = false,
    isLastInGroup: Boolean = false,
) {
    var showDialog by remember {
        mutableStateOf(false)
    }
    if (showDialog) {
        ListDialog(
            onDismiss = { showDialog = false },
        ) {
            items(values) { value ->
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier =
                        Modifier
                            .fillMaxWidth()
                            .clickable {
                                showDialog = false
                                onValueSelected(value)
                            }.padding(horizontal = 16.dp, vertical = 12.dp),
                ) {
                    RadioButton(
                        selected = value == selectedValue,
                        onClick = null,
                    )

                    Text(
                        text = valueText(value),
                        style = MaterialTheme.typography.bodyLarge,
                        modifier = Modifier.padding(start = 16.dp),
                    )
                }
            }
        }
    }

    PreferenceEntry(
        modifier = modifier,
        title = title,
        description = valueText(selectedValue),
        icon = icon,
        onClick = { showDialog = true },
        isEnabled = isEnabled,
        isFirstInGroup = isFirstInGroup,
        isLastInGroup = isLastInGroup,
    )
}

@Composable
inline fun <reified T : Enum<T>> EnumListPreference(
    modifier: Modifier = Modifier,
    noinline title: @Composable () -> Unit,
    noinline icon: (@Composable () -> Unit)?,
    selectedValue: T,
    noinline valueText: @Composable (T) -> String,
    noinline onValueSelected: (T) -> Unit,
    isEnabled: Boolean = true,
    isFirstInGroup: Boolean = false,
    isLastInGroup: Boolean = false,
) {
    ListPreference(
        modifier = modifier,
        title = title,
        icon = icon,
        selectedValue = selectedValue,
        values = enumValues<T>().toList(),
        valueText = valueText,
        onValueSelected = onValueSelected,
        isEnabled = isEnabled,
        isFirstInGroup = isFirstInGroup,
        isLastInGroup = isLastInGroup,
    )
}

@Composable
fun SwitchPreference(
    modifier: Modifier = Modifier,
    title: @Composable () -> Unit,
    description: String? = null,
    icon: (@Composable () -> Unit)? = null,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    isEnabled: Boolean = true,
    isFirstInGroup: Boolean = false,
    isLastInGroup: Boolean = false,
) {
    PreferenceEntry(
        modifier = modifier,
        title = title,
        description = description,
        icon = icon,
        trailingContent = {
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange,
                modifier = Modifier.padding(start = 8.dp)
            )
        },
        onClick = { if (isEnabled) onCheckedChange(!checked) },
        isEnabled = isEnabled,
        isFirstInGroup = isFirstInGroup,
        isLastInGroup = isLastInGroup,
    )
}

@Composable
fun EditTextPreference(
    modifier: Modifier = Modifier,
    title: @Composable () -> Unit,
    icon: (@Composable () -> Unit)? = null,
    value: String,
    onValueChange: (String) -> Unit,
    singleLine: Boolean = true,
    isInputValid: (String) -> Boolean = { it.isNotEmpty() },
    isEnabled: Boolean = true,
    isFirstInGroup: Boolean = false,
    isLastInGroup: Boolean = false,
) {
    var showDialog by remember {
        mutableStateOf(false)
    }

    if (showDialog) {
        TextFieldDialog(
            initialTextFieldValue =
                TextFieldValue(
                    text = value,
                    selection = TextRange(value.length),
                ),
            singleLine = singleLine,
            isInputValid = isInputValid,
            onDone = onValueChange,
            onDismiss = { showDialog = false },
        )
    }

    PreferenceEntry(
        modifier = modifier,
        title = title,
        description = value,
        icon = icon,
        onClick = { showDialog = true },
        isEnabled = isEnabled,
        isFirstInGroup = isFirstInGroup,
        isLastInGroup = isLastInGroup,
    )
}

@Composable
fun SliderPreference(
    modifier: Modifier = Modifier,
    title: @Composable () -> Unit,
    icon: (@Composable () -> Unit)? = null,
    value: Float,
    onValueChange: (Float) -> Unit,
    isEnabled: Boolean = true,
    isFirstInGroup: Boolean = false,
    isLastInGroup: Boolean = false,
) {
    var showDialog by remember {
        mutableStateOf(false)
    }

    var sliderValue by remember {
        mutableFloatStateOf(value)
    }

    if (showDialog) {
        AlertDialog(
            properties = DialogProperties(usePlatformDefaultWidth = false),
            onDismissRequest = { showDialog = false },
            icon = { Icon(painter = painterResource(R.drawable.history), contentDescription = null) },
            title = { Text(stringResource(R.string.history_duration)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDialog = false
                        onValueChange.invoke(sliderValue)
                    },
                ) {
                    Text(stringResource(android.R.string.ok))
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        sliderValue = value
                        showDialog = false
                    },
                ) {
                    Text(stringResource(android.R.string.cancel))
                }
            },
            text = {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = pluralStringResource(R.plurals.seconds, sliderValue.roundToInt(), sliderValue.roundToInt()),
                        style = MaterialTheme.typography.bodyLarge,
                    )

                    Slider(
                        value = sliderValue,
                        onValueChange = { sliderValue = it },
                        valueRange = 15f..60f,
                    )
                }
            },
        )
    }

    PreferenceEntry(
        modifier = modifier,
        title = title,
        description = value.roundToInt().toString(),
        icon = icon,
        onClick = { showDialog = true },
        isEnabled = isEnabled,
        isFirstInGroup = isFirstInGroup,
        isLastInGroup = isLastInGroup,
    )
}

@Composable
fun PreferenceGroupTitle(
    title: String,
    modifier: Modifier = Modifier,
) {
    Text(
        text = title.uppercase(),
        style = MaterialTheme.typography.labelLarge,
        color = MaterialTheme.colorScheme.primary,
        modifier = modifier.padding(16.dp),
    )
}
