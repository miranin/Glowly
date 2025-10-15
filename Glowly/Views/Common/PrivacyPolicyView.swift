//
//  PrivacyPolicyView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Политика конфиденциальности")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Настоящая Политика конфиденциальности регулирует отношения между ООО «Glowly» (далее именуемое — Glowly), и пользователем сети Интернет (далее — Пользователь) по использованию сервиса Glowly.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        policySection(
                            title: "1. Общие положения",
                            content: """
                            Перед использованием сервиса Glowly Пользователь обязан ознакомиться с настоящей Политикой конфиденциальности.
                            
                            В случае несогласия с положениями Политики конфиденциальности присоединиться к нему путем совершения одного из следующих конклюдентных действий:
                            
                            • Нажатие кнопки «Войти» при авторизации по электронной почте на сайте www.glowly.ru, приложении Glowly;
                            • Нажатие кнопки «Зарегистрироваться» при регистрации по электронной почте на сайте www.glowly.ru, приложении Glowly;
                            • Нажатие кнопки «Оформить заказ/Заказать» при оформлении заказа Пользователем без авторизации на сайте www.glowly.ru либо в приложении Glowly, в том числе, мобильном либо приложении в социальных сетях (далее по тексту настоящего Соглашения именуемые — Сайт/сервис);
                            """
                        )
                        
                        policySection(
                            title: "2. Сбор и использование данных",
                            content: """
                            Мы собираем следующие типы информации:
                            
                            • Личные данные: имя, email, номер телефона
                            • Информация о продуктах: списки косметики, предпочтения
                            • Техническая информация: тип устройства, версия ОС
                            
                            Ваши данные используются для:
                            • Предоставления персонализированных рекомендаций
                            • Улучшения качества сервиса
                            • Отправки уведомлений (с вашего согласия)
                            """
                        )
                        
                        policySection(
                            title: "3. Защита данных",
                            content: """
                            Мы применяем современные технологии шифрования для защиты ваших данных.
                            
                            Пароли хранятся в зашифрованном виде. Данные банковских карт не хранятся на наших серверах.
                            """
                        )
                        
                        policySection(
                            title: "4. Ваши права",
                            content: """
                            Вы имеете право:
                            • Получить доступ к своим данным
                            • Исправить неточные данные
                            • Удалить свой аккаунт и данные
                            • Отозвать согласие на обработку данных
                            
                            Для реализации ваших прав свяжитесь с нами: support@glowly.ru
                            """
                        )
                        
                        policySection(
                            title: "5. Контакты",
                            content: """
                            По вопросам, связанным с политикой конфиденциальности, обращайтесь:
                            
                            Email: support@glowly.ru
                            Телефон: +7 (700) 123-45-67
                            """
                        )
                    }
                    
                    // Accept Button
                    Button {
                        dismiss()
                    } label: {
                        Text("понятно")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Theme.accent)
                            .cornerRadius(26)
                    }
                    .padding(.top, 24)
                }
                .padding(24)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}

