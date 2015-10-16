active proctype p() {
    true;
}

never {
acc:if
    :: goto acc;
    :: goto bacc;
    fi;
bacc:if
    :: goto acc;
    :: goto bacc;
    fi
}
