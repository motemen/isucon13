package main

import (
	"fmt"
)

func redisTotalTipsKey(userID int64) string {
	return fmt.Sprintf("total_tip:%d", userID)
}

func redisTotalReactionsKey(userID int64) string {
	return fmt.Sprintf("total_reactions:%d", userID)
}
