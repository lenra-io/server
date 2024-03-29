import "../css/token-input.css"

(() => {
    const form = document.querySelector('form');
    const inputs = [...form.querySelectorAll('fieldset.token>input:not([type="hidden"])')];
    const tokenInput = form.querySelector('fieldset.token>input[type="hidden"]');
    const resendButton = form.querySelector('a.btn');


    inputs.forEach((input, i) => {
        input.addEventListener('keydown', (e) => {
            // if the keycode is backspace (8) and the current field is empty focus the input before the current.
            if (e.keyCode === 8 && e.target.value === '') {
                inputs[Math.max(0, i - 1)].focus();
            }
        })
        input.addEventListener('input', (e) => {
            // take the first character of the input and set the input to that value
            const [first, ...rest] = e.target.value.replace(/[^a-zA-Z0-9]/g, '');
            e.target.value = first ?? '' // first will be undefined when backspace was entered, so set the input to ""
            const isLast = i === inputs.length - 1
            const didInsertContent = first !== undefined
            if (didInsertContent && !isLast) {
                // continue to input the rest of the string
                fillNextInputs(i + 1, rest.join(''));
            }
            tokenInput.value = inputs.map(({ value }) => value).join('');
        })
    });

    document.addEventListener('paste', (e) => {
        // Let inputs handle pasting if they are focused
        if (document.activeElement instanceof HTMLInputElement || document.activeElement instanceof HTMLTextAreaElement) return;
        const pastedData = e.clipboardData.getData('text/plain');
        fillNextInputs(0, pastedData);
    });

    function fillNextInputs(pos, text) {
        if (pos >= inputs.length) return;
        inputs[pos].focus();
        inputs[pos].value = text;
        inputs[pos].dispatchEvent(new Event('input', { bubbles: true, cancelable: true }));
    }

    if (resendButton) {
        Object.defineProperty(resendButton, "disabled", {
            get() {
                return this.hasAttribute("disabled");
            },
            set(value) {
                if (value) {
                    this.setAttribute("disabled", "");
                } else {
                    this.removeAttribute("disabled");
                }
            }
        });

        resendButton.addEventListener('click', (e) => {
            e.preventDefault();
            if (resendButton.disabled) return;
            resendButton.disabled = true;
            fetch(resendButton.href, {
                method: 'POST',
                body: new URLSearchParams({
                    _csrf_token: form.querySelector('input[name="_csrf_token"]').value
                })
            })
                .then((response) => {
                    if (response.ok) {
                        form.reset();
                        startResendDelay();
                    }
                });
        });
        startResendDelay();
    }

    function startResendDelay() {
        setTimeout(() => {
            resendButton.disabled = false;
        }, 10000);
    }
})()