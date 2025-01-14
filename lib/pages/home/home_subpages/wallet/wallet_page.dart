import 'package:animate_do/animate_do.dart';
import 'package:ethller/pages/home/home_subpages/wallet/bloc/wallet_bloc.dart';
import 'package:ethller/widgets/common/other/custom_container.dart';
import 'package:ethller/widgets/common/other/wallet_summary.dart';
import 'package:ethller_api_interface/ethller_api_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:async/async.dart';
import 'package:money_converter/money_converter.dart';
import 'package:money_converter/Currency.dart';

class WalletPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: EdgeInsets.only(top: 165 + topPadding),
        child: RefreshIndicator(
          onRefresh: () async {
            if (walletUID != '') {
              BlocProvider.of<WalletBloc>(context)
                  .add(WalletInitEvent(walletUID));
            }
            await Future.delayed(Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: 20, width: double.infinity),
                FadeIn(
                  duration: const Duration(milliseconds: 300),
                  child: SlideInUp(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        WalletSummary(),
                        _TxsList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TxsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        if (state is WalletLoadedState) {
          final wallet = state.wallet;
          wallet.transactions
              .sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
          return ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(0),
            physics: NeverScrollableScrollPhysics(),
            itemCount: wallet.transactions.length > 25
                ? 25
                : wallet.transactions.length,
            itemBuilder: (BuildContext context, int index) {
              return SlideInUp(
                duration: Duration(milliseconds: 300),
                child: _TxCard(
                  walletId: wallet.id,
                  tx: wallet.transactions[index],
                ),
              );
            },
          );
        }
        if (state is WalletInitial) {
          return Center(
              child: Text('No wallet added',
                  style: Theme.of(context).textTheme.bodyText1));
        }

        if (state is WalletNoConnectionState) {
          return Center(
              child: Text('No internet connection',
                  style: Theme.of(context).textTheme.bodyText1));
        }

        if (state is WalletErrorState) {
          return Center(
              child: Text(state.appError.message,
                  style: Theme.of(context).textTheme.bodyText1));
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _TxCard extends StatelessWidget {
  final WalletTransaction tx;
  final String walletId;
  final AsyncMemoizer memoizer = AsyncMemoizer();

  _TxCard({
    Key key,
    @required this.tx,
    @required this.walletId,
  }) : super(key: key);

  _fetchData() {
    return this.memoizer.runOnce(() async {
      return MoneyConverter.convert(
          Currency(Currency.USD), Currency(Currency.INR));
    });
  }


  @override
  Widget build(BuildContext context) {
    final inUsd = tx.value * ethUsd;
    return CustomContainer(
      height: 80,
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          Icon(
            tx.from == walletId ? Icons.arrow_downward : Icons.arrow_upward,
            color: tx.from == walletId ? Colors.red : Colors.green,
            size: 30,
          ),
          SizedBox(width: 5),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx.from == walletId ? 'Send' : 'Recived',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${tx.timeStamp.day}/${tx.timeStamp.month}/${tx.timeStamp.year} ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                '${tx.timeStamp.hour}:${tx.timeStamp.minute} hs',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Spacer(),
          Container(
            margin:
                const EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 30),
            height: double.infinity,
            width: 1,
            color: Colors.grey[800],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.value.toStringAsFixed(8),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    ' ETH',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                FutureBuilder(future: _fetchData(), builder: (context, snapshot) {
                  return Text(
                    ((snapshot.hasData ? snapshot.data : 0) * inUsd).toStringAsFixed(2),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                    ),
                  );
                }),
                  Text(
                    ' INR',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
