# Який варіант курсорів macOS ставить tasks\96-Cursors.ps1 (архів у assets\cursors\).
# Значення мають збігатися з назвами тек в архіві без номера на початку.
# Не потрібні курсори - запускайте з -Skip Cursors.
#
# УВАГА: вибір за замовчуванням - припущення, не підтверджене.
# Змініть під себе й перезапустіть задачу: -Only Cursors.
@{
    # 'Sierra and newer'   - таймер очікування синій
    # 'El Capitan and before' - таймер очікування веселковий
    Generation = 'Sierra and newer'

    # 'No Shadow' | 'With Shadow'
    Shadow     = 'No Shadow'

    # 'Normal' | 'Large' | 'XtraLarge'
    Size       = 'Normal'
}
