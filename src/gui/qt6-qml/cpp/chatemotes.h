#ifndef CHATEMOTES_H
#define CHATEMOTES_H

#include <QString>
#include <QRegularExpression>

// Vergrößert Unicode-Emoji in einer (bereits HTML-formatierten) Chatzeile auf
// ~22px – ähnlich den Bild-Emotes des Qt-Widgets-Clients. Zusammenhängende
// Emoji-Sequenzen (inkl. Variations-Selektoren / ZWJ / Keycaps) werden in einen
// größeren font-size-Span gewrappt. Wird von Game- und Lobby-Chat genutzt.
inline QString enlargeEmojis(const QString &html)
{
    static const QRegularExpression emojiRe(QStringLiteral(
        "([\\x{1F000}-\\x{1FAFF}\\x{2600}-\\x{27BF}\\x{2B00}-\\x{2BFF}"
        "\\x{2190}-\\x{21FF}\\x{2300}-\\x{23FF}\\x{2900}-\\x{297F}"
        "\\x{FE00}-\\x{FE0F}\\x{200D}\\x{20E3}]+)"));
    QString r = html;
    r.replace(emojiRe, QStringLiteral(
        "<span style=\"font-size:22px; font-family:'Noto Color Emoji';\">\\1</span>"));
    return r;
}

#endif // CHATEMOTES_H
