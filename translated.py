import json
import os

language_mapping = {
    'en': 'English',
    'ar': 'Arabic',
    'zh': 'Chinese',
    'nl': 'Dutch',
    'fr': 'French',
    'ka': 'Georgian',
    'de': 'German',
    'el': 'Greek',
    'id': 'Indonesian',
    'it': 'Italian',
    'pl': 'Polish',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'es': 'Spanish',
    'zh_TW': 'Traditional Chinese Taiwan',
    'tr': 'Turkish',
    'uk': 'Ukrainian',
    'vi': 'Vietnamese',
}

def load_translation(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        return json.load(file)

def are_translations_equal(translation1, translation2):
    return translation1 == translation2

def count_translated_texts(english_data, translation_data):
    total_texts = len(english_data.keys())
    translated_texts = sum(1 for key, value in translation_data.items() if value and not are_translations_equal(value, english_data.get(key, '')))

    return translated_texts, total_texts

def calculate_percentage(translated_count, total_count):
    if total_count == 0:
        return 0.0
    return (translated_count / total_count) * 100

def update_readme_statistics(readme_path, statistics_content):
    with open(readme_path, 'r', encoding='utf-8') as readme_file:
        readme_content = readme_file.read()

    start_marker = "<!-- START_TRANSLATION_STATS -->"
    end_marker = "<!-- END_TRANSLATION_STATS -->"
    start_index = readme_content.find(start_marker) + len(start_marker)
    end_index = readme_content.find(end_marker)

    updated_readme_content = (
        readme_content[:start_index] + "\n" +
        statistics_content + "\n" +
        readme_content[end_index:]
    )

    with open(readme_path, 'w', encoding='utf-8') as readme_file:
        readme_file.write(updated_readme_content)

def main():
    arb_folder_path = 'lib/localization'
    english_file_path = os.path.join(arb_folder_path, 'app_en.arb')

    english_data = load_translation(english_file_path)
    statistics_rows = []

    for file_name in os.listdir(arb_folder_path):
        if file_name.endswith('.arb') and file_name != 'app_en.arb':
            language_code = file_name.replace('app_', '').replace('.arb', '')
            language_name = language_mapping.get(language_code, 'Unknown')
            file_path = os.path.join(arb_folder_path, file_name)
            translation_data = load_translation(file_path)
            translated_texts, total = count_translated_texts(english_data, translation_data)
            translated_percentage = calculate_percentage(translated_texts, total)
            statistics_rows.append((language_name, language_code, translated_texts, total, translated_percentage))

    statistics_rows.sort(key=lambda x: x[4], reverse=True)

    overall_translated_texts = sum(row[2] for row in statistics_rows)
    overall_total_texts = sum(row[3] for row in statistics_rows)
    overall_percentage = calculate_percentage(overall_translated_texts, overall_total_texts)

    statistics_content = "| Language       | Language Code | Translated Texts | Total Texts | Translation Percentage |\n"
    statistics_content += "|----------------|---------------|------------------|-------------|------------------------|\n"

    for row in statistics_rows:
        statistics_content += f"| {row[0]} | {row[1]} | {row[2]} | {row[3]} | {row[4]:.2f}% |\n"

    statistics_content += f"| Overall        | - | {overall_translated_texts} | {overall_total_texts} | {overall_percentage:.2f}% |"

    readme_path = 'README.md'
    update_readme_statistics(readme_path, statistics_content)

if __name__ == "__main__":
    main()
