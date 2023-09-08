import "../css/form.css"

(() => {
    const form = document.querySelector("form");
    const submitButton = form.querySelector('button[type="submit"]');
    form.addEventListener('submit', _event => setSubmitAction());
    form.addEventListener('change', _event => {
        setSubmitAction();
        checkValidity();
    });
    form.addEventListener('input', _event => checkValidity());
    function setSubmitAction() {
        const currentAction = form.querySelector('input[name="user[submit_action]"]:checked');
        if (currentAction) {
            submitButton.innerText = currentAction.dataset.submit;
            form.action = currentAction.dataset.formAction;
            history.replaceState({ action: currentAction.value }, "", "./" + currentAction.value);
        }
    }
    function checkValidity() {
        submitButton.disabled = !form.checkValidity();
    }
    form.querySelectorAll('fieldset.password').forEach(passwordFieldset => {
        const passwordLabel = passwordFieldset.querySelector('label');
        const passwordInput = passwordFieldset.querySelector('input[type="password"]');
        const rules = passwordFieldset.querySelectorAll('ul.rules>li');
        passwordLabel.addEventListener('click', event => {
            if (event.layerY > event.target.offsetHeight) {
                const shown = passwordInput.type === 'text';
                passwordInput.type = shown ? 'password' : 'text';
                passwordLabel.classList.toggle('lenra-icon-eye');
                passwordLabel.classList.toggle('lenra-icon-eye-off');
            }
        });
        passwordInput.addEventListener('input', _event => {
            const currentAction = form.querySelector('input[name="user[submit_action]"]:checked');
            if (currentAction && currentAction.value === "register") {
                rules.forEach(rule => {
                    let valid = false;
                    switch (rule.dataset.kind) {
                        case 'min':
                            valid = passwordInput.value.length >= rule.dataset.count;
                            break;
                        case 'format':
                            valid = new RegExp(rule.dataset.pattern).test(passwordInput.value);
                            break;
                    }
                    if (valid) {
                        rule.classList.add('valid');
                        rule.classList.remove('invalid');
                    }
                    else {
                        rule.classList.add('invalid');
                        rule.classList.remove('valid');
                    }
                });
            }
        });
    });
})();